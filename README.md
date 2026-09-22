# document-retrieval-service

Reference implementation for the **BlueEagle Financial Services KYC Document
Portal** used in the AWS Foundations sprint. A client (case/customer) has a
reference number; against that reference they can upload verification
documents and retrieve anything they've previously submitted. S3 itself,
keyed by `{clientRef}/{filename}`, is the system of record — there is no
database in this service.

This repo is the **application code** the Task Brief's Web/App-tier build
steps deploy. Clone it to read and cross-check the code; it is not where you
submit your own work (see **Submitting your own work**, below).

```
git clone https://gitlab.com/wandaprep/document-retrieval-service.git
```

## What's in this repo

```
document-retrieval-service/
├── pom.xml
├── src/main/java/io/blueeagle/docservice/
│   ├── DocServiceApplication.java     # Spring Boot entry point
│   ├── config/S3Config.java           # S3Client bean, DefaultCredentialsProvider
│   └── controller/
│       ├── HealthController.java      # GET /health - ALB target-group check
│       └── DocumentController.java    # GET/PUT/LIST under /api/documents
├── src/main/resources/
│   ├── application.properties         # env-var driven region + bucket
│   └── static/                        # the KYC portal landing page
│       ├── index.html
│       ├── css/portal.css
│       └── js/portal.js
└── scripts/
    ├── user-data.sh                   # EC2 Launch Template bootstrap
    └── docservice.service             # systemd unit
```

## API

All endpoints are under `/api/documents` and use the client reference as an
S3 key prefix.

| Method | Path | What it does |
|---|---|---|
| `PUT` | `/api/documents/{clientRef}/{filename}` | Upload a document (`multipart/form-data`, field `file`). Writes to S3 as `{clientRef}/{filename}`. Returns `201` with the stored key and size. |
| `GET` | `/api/documents/{clientRef}/{filename}` | Stream a single document back out of S3 with its original content type. Returns `404` if the key doesn't exist. |
| `GET` | `/api/documents/{clientRef}` | List every document on file for that client reference (filename, size, last-modified). Backs the portal's document table. |
| `GET` | `/health` | Liveness check for `blueeagle-prod-app-alb`. Doesn't touch S3. |

No delete endpoint exists on purpose — the app-tier IAM role
(`blueeagle-prod-app-role`) is scoped to `s3:GetObject`, `s3:PutObject` and
`s3:ListBucket` on `blueeagle-prod-documents` only. It is not capable of
`s3:DeleteObject`, so a compromised or buggy instance can add and read
documents but can never destroy one.

## The landing page

`src/main/resources/static/index.html` is served automatically by Spring
Boot's static-resource handling at `/` — no separate web server or extra
routing needed, the same jar serves the API and the UI. It's a thin,
framework-free client (`js/portal.js`) over the three endpoints above:

1. Enter a client reference and click **Load my documents** → calls
   `GET /api/documents/{clientRef}`.
2. Pick a file and click **Upload** → calls
   `PUT /api/documents/{clientRef}/{filename}`, then reloads the list.
3. Click **View / download** on any row → opens
   `GET /api/documents/{clientRef}/{filename}` directly.

This is a reference UI, not a production KYC portal — there's no
authentication in front of it, so anyone who knows (or guesses) a client
reference can list and read that reference's documents. In a real system
this would sit behind Cognito or an equivalent identity provider, with the
client reference derived from the authenticated session rather than typed
into a text box. That's a deliberate simplification, kept out of scope so
the sprint stays focused on the compute/storage/networking build.

## Running it locally

Requires Java 17 and Maven, and AWS credentials for a bucket you control
(a local AWS CLI profile is picked up automatically by
`DefaultCredentialsProvider` — no keys are ever hardcoded).

```bash
export AWS_REGION=eu-west-2
export S3_BUCKET_NAME=your-test-bucket
mvn spring-boot:run
```

Then open `http://localhost:8080` for the portal, or hit the API directly:

```bash
curl -F "file=@passport.pdf" http://localhost:8080/api/documents/CUST-100482/passport.pdf -X PUT
curl http://localhost:8080/api/documents/CUST-100482
curl http://localhost:8080/api/documents/CUST-100482/passport.pdf -o passport.pdf
```

## How it's deployed in the sprint environment

`blueeagle-prod-app-lt` (the app-tier Launch Template) runs
`scripts/user-data.sh` on every instance boot:

1. Installs Java 17 and Maven.
2. Clones this repo and runs `mvn clean package`.
3. Copies the built jar to `/opt/docservice/`.
4. Installs `scripts/docservice.service` as a systemd unit, with
   `AWS_REGION` and `S3_BUCKET_NAME` substituted in from the Launch
   Template's own instance metadata/environment.
5. Enables and starts the service.

`blueeagle-prod-app-asg` launches every app-tier instance from that Launch
Template, so there's one source of truth for what's running — this repo —
never a hand-configured instance or a golden AMI drifting out of sync.

## Submitting your own work

This repository is the **clone source** only — it's how you read and
cross-check the reference implementation. You do not have write access to
it, and your own build does not get pushed here.

Push your own completed work to your **own** GitLab account, not into the
`wandaprep` group:

```bash
git remote add origin git@gitlab.com:<your-username>/document-retrieval-service.git
git push -u origin main
```
