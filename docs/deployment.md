# Deployment

## Prerequisites

The deployment requires:

-   AWS account
-   Java 17
-   Maven
-   Terraform
-   AWS CLI
-   GitHub or GitLab repository
-   Configured AWS OIDC provider and CI/CD IAM role
-   Terraform state/bootstrap resources
-   Required application and infrastructure variables

## Pipeline Stages

Both CI/CD implementations follow the same logical deployment model:

``` text
test
  |
build
  |
publish
  |
infra
  |
deploy_pointer
  |
refresh
  |
validate
  |
summary
```

## 1. Test

Maven runs the application test suite using Java 17.

``` bash
mvn -B test
```

## 2. Build

The application is packaged as:

``` text
target/document-retrieval-service.jar
```

Tests are not repeated during this stage because they already ran in the
test stage.

## 3. Publish

The exact JAR produced by the build is uploaded to S3:

``` text
document-retrieval-service/<GIT_SHA>/document-retrieval-service.jar
```

The commit SHA makes each application artifact independently
identifiable.

## 4. Infrastructure

Terraform performs:

``` bash
terraform init
terraform validate
terraform plan
terraform apply -auto-approve
```

The infrastructure layer includes the networking, ALB, target group,
Launch Template, ASG, IAM, S3, and related resources required by the
application platform.

## 5. Update SSM Deployment Pointer

The pipeline updates:

``` text
/blueeagle/prod/document-retrieval-service/artifact-key
```

with the exact S3 key for the artifact being deployed.

Example:

``` text
document-retrieval-service/<GIT_SHA>/document-retrieval-service.jar
```

The pipeline verifies that the artifact exists in S3 before updating the
pointer.

## 6. ASG Instance Refresh

After the SSM pointer has been updated, the pipeline starts an Auto
Scaling Group Instance Refresh.

This ordering is important:

``` text
Publish artifact
      |
      v
Update SSM pointer
      |
      v
Start instance refresh
```

New instances therefore know exactly which application version they must
download during bootstrap.

## 7. Wait for Refresh

The pipeline waits for the refresh to reach:

``` text
Successful
```

Failure states cause the pipeline to fail.

## 8. Application Validation

The pipeline retrieves the ALB DNS name and validates:

``` bash
curl http://<ALB-DNS>/health
```

Expected:

``` text
OK
```

It then validates:

``` bash
curl http://<ALB-DNS>/documents/test-document.txt
```

Expected:

``` text
Hello from BlueEagle document retrieval service
```

## GitHub vs GitLab

The project demonstrates the same AWS deployment pattern through two
CI/CD platforms.

### GitHub Actions

GitHub Actions uses the GitHub OIDC identity provider and assumes the
AWS CI/CD role without long-lived AWS secrets.

### GitLab CI

GitLab CI uses the GitLab OIDC identity provider and assumes the
dedicated:

``` text
gitlab-ci-tf-role
```

The GitLab pipeline similarly receives short-lived AWS STS credentials.

The application deployment model remains the same regardless of CI/CD
platform.
