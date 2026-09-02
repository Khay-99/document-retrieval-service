# document-retrieval-service

A minimal Spring Boot service used as the App-layer application for the AWS platform
build. It exposes two endpoints:

| Method | Path                | Purpose                                                          |
|--------|---------------------|-------------------------------------------------------------------|
| GET    | `/health`           | Liveness check. Returns `OK`.                                     |
| GET    | `/documents/{key}`  | Fetches the given object key from S3 and streams it back to the caller. |

There is no database and no queue. The only external dependency is one S3 bucket, and
credentials are never configured directly — the app relies entirely on
`DefaultCredentialsProvider`, which resolves to your local CLI profile on a laptop and to
the EC2 instance's attached IAM role in every other environment.

## 1. Build and run locally (optional, for quick iteration)

Prerequisites: Java 17, Maven, an AWS CLI profile with read access to a test bucket.

```bash
mvn clean package
AWS_REGION=eu-west-2 S3_BUCKET_NAME=your-test-bucket java -jar target/document-retrieval-service.jar
```

Then:

```bash
curl http://localhost:8080/health
curl http://localhost:8080/documents/some-object-key.txt
```

A 502 from `/documents/{key}` almost always means an IAM permissions problem, not a bug
in the app — check the error message in the response body before assuming the code is
broken.

## 2. Deploying via Launch Template + Auto Scaling Group (blueeagle-prod-app-lt / blueeagle-prod-app-asg)

This app is meant to run as a systemd service on every instance in the App tier's Auto
Scaling Group, started automatically from the launch template's user data — never
deployed by hand over SSH. That matters for the resilience story in the platform brief:
whenever the ASG launches a replacement instance (because one failed a health check, or
because it scaled out under load), that instance must come up running this service with
zero manual steps.

### 2.1 One-time setup

1. This repository is hosted at `https://gitlab.com/wandaprep/document-retrieval-service.git` - clone it from there. When you submit your own completed work, push it to your own GitLab account, not back into the wandaprep group.
2. Confirm `blueeagle-prod-app-role` (least-privilege, `s3:GetObject` / `s3:PutObject` on your
   one bucket) already exists — it gets attached via the launch template, not per instance.
3. Open `scripts/user-data.sh` and replace the three `REPLACE_ME_*` placeholders with
   your repo URL, region, and bucket name.

### 2.2 Create the Launch Template

In the EC2 console, under **Launch Templates**, create `blueeagle-prod-app-lt` with:

- **AMI:** Amazon Linux 2023
- **Instance type:** t3.micro (or your account's free-tier equivalent)
- **Key pair:** your existing key pair, for break-glass SSH access only
- **Network settings:** `blueeagle-prod-app-sg` (inbound only from `blueeagle-prod-web-sg`,
  nothing from the internet directly)
- **IAM instance profile:** `blueeagle-prod-app-role`
- **Tags:** apply the standard tag set from the platform brief (Name, Environment,
  Project, ManagedBy, Owner) so every instance the ASG launches inherits them
- **Advanced details → User data:** paste the full, edited contents of
  `scripts/user-data.sh`

### 2.3 Create the Auto Scaling Group

Create `blueeagle-prod-app-asg` from this launch template:

- **Subnets:** your private subnets, across at least two Availability Zones
- **Load balancing:** attach it to the `blueeagle-prod-app-alb` target group (internal ALB)
  rather than launching instances that aren't behind anything
- **Health checks:** enable ELB health checks, not just EC2 status checks, so the ASG
  reacts to the ALB's view of instance health, not just whether the host is up
- **Group size:** a sensible min/desired/max (e.g. 2/2/4) — don't leave it at 1, or you
  haven't actually built resilience, just a single instance with extra steps

### 2.4 Verify it came up correctly

SSH into an instance (via the Web tier or Session Manager) and check:

```bash
sudo systemctl status docservice
journalctl -u docservice -n 100 --no-pager
curl http://localhost:8080/health
```

Then confirm in the `blueeagle-prod-app-alb` target group console that the instance shows as
**healthy**, and that Nginx (pointed at the ALB's DNS name, not an instance IP) is
successfully proxying through.

### 2.5 Why this matters for the resilience story

Because the whole install-and-start process lives in the launch template's user data,
recovering from a failed App instance should require nothing from you: terminate an
instance, and the ASG launches a replacement from `blueeagle-prod-app-lt` in another
Availability Zone, the new instance registers itself with `blueeagle-prod-app-alb`, and
traffic resumes once its health check passes. If any step here still needs a human, that
gap is exactly what should go in your troubleshooting notes.

## 3. Configuration reference

| Environment variable | Set where                                  | Purpose                        |
|-----------------------|--------------------------------------------|---------------------------------|
| `AWS_REGION`          | `docservice.service` (systemd Environment=) | Region for the S3 client        |
| `S3_BUCKET_NAME`      | `docservice.service` (systemd Environment=) | Bucket the app is allowed to read/write |

Neither value should ever be committed to this repo with a real bucket name — the
placeholders in `scripts/docservice.service` are deliberately obvious so you don't forget
to replace them per environment.
