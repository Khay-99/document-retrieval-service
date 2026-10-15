<<<<<<< HEAD
# Document Retrieval Service

A production-style Spring Boot application deployed on AWS using **Terraform, GitLab CI/CD, GitHub Actions, AWS OIDC, Amazon S3, SSM Parameter Store, EC2 Auto Scaling, and an Application Load Balancer**.

The project demonstrates a **build-once, deploy-exact-artifact** application delivery pattern with immutable S3 artifacts and automated infrastructure/application rollout.

---

## Table of Contents

* [Overview](#overview)
* [Architecture](#architecture)
* [Application](#application)
* [CI/CD Pipeline](#cicd-pipeline)
* [Immutable Artifact Deployment](#immutable-artifact-deployment)
* [Security](#security)
* [Infrastructure](#infrastructure)
* [Deployment Flow](#deployment-flow)
* [Validation](#validation)
* [Repository Structure](#repository-structure)
* [Local Development](#local-development)
* [Documentation](#documentation)
* [Cleanup](#cleanup)

---

## Overview

The Document Retrieval Service is a minimal Spring Boot application used as the **App layer** of an AWS platform engineering implementation.

The service exposes two endpoints:

| Method | Path               | Purpose                                                      |
| ------ | ------------------ | ------------------------------------------------------------ |
| `GET`  | `/health`          | Application health check. Returns `OK`.                      |
| `GET`  | `/documents/{key}` | Retrieves an object from Amazon S3 and returns its contents. |

The application has:

* No database
* No message queue
* Amazon S3 as its external application dependency
* Java 17
* Spring Boot 3.3.4
* Maven
* AWS SDK for Java
* IAM-based authentication using `DefaultCredentialsProvider`

---

## Architecture

![Architecture Diagram](architecture/architecture.png)

All AWS infrastructure is managed through Terraform.

---

## Application

### Health Check

```bash
curl http://localhost:8080/health
```

Response:

```text
OK
```

### Document Retrieval

```bash
curl http://localhost:8080/documents/test-document.txt
```

Example response:

```text
Hello from BlueEagle document retrieval service
```

The application obtains AWS credentials through the AWS SDK `DefaultCredentialsProvider`.

This allows the same application to use:

* A local AWS CLI profile during development
* The EC2 instance IAM role when running in AWS

No AWS access keys are embedded in the application.

---

## CI/CD Pipeline

The project contains both **GitHub Actions and GitLab CI/CD implementations** of the deployment workflow.

The pipeline follows:

```text
Test
  ↓
Build
  ↓
Publish immutable artifact
  ↓
Terraform infrastructure
  ↓
Update SSM deployment pointer
  ↓
ASG instance refresh
  ↓
Wait for refresh
  ↓
ALB health validation
  ↓
Document endpoint validation
```

### Build Once, Deploy the Same Artifact

The application is compiled once per commit.

The resulting JAR is stored using the Git commit SHA:

```text
s3://blueeagle-prod-app-doc-artifacts/
└── document-retrieval-service/
    └── <git-sha>/
        └── document-retrieval-service.jar
```

The pipeline then updates the SSM deployment pointer:

```text
/blueeagle/prod/document-retrieval-service/artifact-key
```

Example value:

```text
document-retrieval-service/<git-sha>/document-retrieval-service.jar
```

EC2 instances retrieve this pointer during bootstrap and download the exact immutable artifact.

This separates:

**Infrastructure management**

from

**Application version deployment**

---

## Immutable Artifact Deployment

The deployment model intentionally separates the immutable artifact from the mutable deployment pointer.

```text
Git Commit SHA
      │
      ▼
Immutable S3 Artifact
      │
      ▼
SSM Parameter
      │
      ▼
EC2 User Data
      │
      ▼
Download Exact JAR
      │
      ▼
systemd
      │
      ▼
Application
```

This provides:

* Repeatable deployments
* Exact version identification
* No dependency on the latest artifact
* Easier rollback
* Clear separation between infrastructure and application delivery

---

## Security

### GitHub and GitLab OIDC

The CI/CD pipelines authenticate to AWS using **OIDC federation**.

No long-lived AWS access keys are stored in GitHub or GitLab.

The workflow exchanges the CI platform's OIDC token with AWS STS and receives short-lived credentials for the job.

```text
GitHub/GitLab
     │
     │ OIDC token
     ▼
AWS IAM OIDC Provider
     │
     ▼
STS AssumeRoleWithWebIdentity
     │
     ▼
Temporary AWS credentials
```

### AWS IAM

The architecture uses IAM roles rather than static credentials:

* CI/CD IAM role for AWS deployment operations
* EC2 instance role for application access
* S3 permissions for application artifacts/documents

The application itself does not contain AWS credentials.

---

## Infrastructure

The AWS platform is managed with Terraform and includes the application delivery components required by the platform.

Key components include:

* Amazon VPC
* Public and private subnets
* Application Load Balancer
* Target Group
* EC2 Launch Template
* Auto Scaling Group
* IAM roles and instance profile
* Amazon S3 artifact bucket
* Amazon S3 document bucket
* SSM Parameter Store
* Security Groups

The App tier runs behind the ALB and is designed to operate from private subnets.

The Auto Scaling Group uses ELB health checks and supports automated instance replacement.

---

## Deployment Flow

When a new application version is pushed:

1. Maven tests the application.
2. Maven builds the JAR.
3. The JAR is uploaded to S3 using the Git commit SHA.
4. Terraform validates and applies the infrastructure.
5. SSM is updated with the new artifact key.
6. The Auto Scaling Group starts an instance refresh.
7. New instances launch from the Launch Template.
8. EC2 user data reads the SSM deployment pointer.
9. The instance downloads the exact JAR from S3.
10. systemd starts the application.
11. The instance registers with the ALB.
12. The pipeline waits for the refresh to complete.
13. The ALB `/health` endpoint is validated.
14. The `/documents/test-document.txt` endpoint is validated.

No manual application deployment over SSH is required.

---

## Validation

The pipeline performs end-to-end validation after deployment.

### ALB Health

```bash
curl http://<ALB-DNS>/health
```

Expected:

```text
OK
```

### Document Retrieval

```bash
curl http://<ALB-DNS>/documents/test-document.txt
```

Expected:

```text
Hello from BlueEagle document retrieval service
```

This validates the complete path:

```text
Client
  ↓
ALB
  ↓
EC2
  ↓
Spring Boot
  ↓
S3
  ↓
Document
```

---

## Repository Structure

```text
document-retrieval-service/
│
├── .github/
│   └── workflows/
│       └── deploy.yml
│
├── .gitlab-ci.yml
│
├── docs/
│   ├── architecture.md
│   ├── deployment.md
│   ├── troubleshooting.md
│   └── lessons-learned.md
│
├── scripts/
│   ├── user-data.sh
│   └── docservice.service
│
├── src/
│   └── main/
│
├── terraform/
│   └── infrastructure/
│
├── pom.xml
└── README.md
```

---

## Local Development

### Prerequisites

* Java 17
* Maven
* AWS CLI
* AWS credentials with read access to the test S3 bucket

Build the application:

```bash
mvn clean package
```

Run locally:

```bash
AWS_REGION=us-east-1 \
S3_BUCKET_NAME=your-test-bucket \
java -jar target/document-retrieval-service.jar
```

Test:

```bash
curl http://localhost:8080/health
```

```bash
curl http://localhost:8080/documents/<object-key>
```

---

## Documentation

Additional implementation details are available under [`docs/`](docs/):

* [`architecture.md`](docs/architecture.md) — architecture and component design
* [`deployment.md`](docs/deployment.md) — CI/CD and deployment workflow
* [`troubleshooting.md`](docs/troubleshooting.md) — common deployment and runtime issues
* [`lessons-learned.md`](docs/lessons-learned.md) — platform engineering lessons and design decisions

---

## Cleanup

The normal deployment pipeline does **not** automatically destroy infrastructure.

Infrastructure cleanup should be performed deliberately using Terraform:

```bash
cd terraform/infrastructure
terraform destroy
```

For GitHub Actions, a separate manually triggered destroy workflow can be used where appropriate.

This separation prevents an infrastructure teardown from being accidentally coupled to the normal application deployment lifecycle.

---

## Key Engineering Outcomes

This implementation extends the original application deployment model with:

* Infrastructure as Code using Terraform
* GitHub Actions and GitLab CI/CD
* GitHub/GitLab OIDC authentication to AWS
* Short-lived AWS credentials
* Immutable SHA-based application artifacts
* SSM-based deployment pointer
* Automated ASG instance refresh
* Automated ALB and application validation
* Zero manual application deployment over SSH
* Separation of infrastructure provisioning from application version deployment
* Repeatable, self-healing application deployment through the Auto Scaling Group
=======
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
>>>>>>> origin/main
