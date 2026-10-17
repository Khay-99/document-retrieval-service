# Lessons Learned

## 1. Build Once, Deploy the Same Artifact

The application should not be rebuilt independently for different
deployment steps.

The pipeline builds one JAR and publishes it using the Git commit SHA:

``` text
document-retrieval-service/<SHA>/document-retrieval-service.jar
```

The same artifact is then deployed to the EC2 environment.

This improves traceability and reduces the risk of different builds
being deployed to different instances.

## 2. Separate Immutable Artifacts from Deployment State

The S3 artifact is immutable.

The SSM parameter is mutable.

``` text
S3
 |
 +-- SHA A
 +-- SHA B
 +-- SHA C
```

SSM points to the version currently intended for deployment:

``` text
SSM
 |
 +--> SHA C
```

This provides a clean separation between artifact storage and deployment
state.

## 3. Deployment Ordering Matters

One of the key issues discovered during implementation was the order of
operations.

An ASG Instance Refresh was initially able to launch new instances
before the SSM deployment pointer existed.

The new instance therefore could not determine which artifact to
download.

The corrected sequence is:

``` text
Artifact published
       ↓
SSM pointer updated
       ↓
ASG instance refresh
       ↓
New instance bootstraps
       ↓
ALB validation
```

This is an important dependency in automated infrastructure-driven
deployments.

## 4. OIDC Removes Long-Lived CI Credentials

GitHub Actions and GitLab CI do not require permanent AWS access keys
stored as repository secrets.

Instead:

``` text
CI OIDC token
      ↓
AWS IAM trust policy
      ↓
STS
      ↓
Short-lived credentials
```

This reduces credential-management overhead and limits the lifetime of
CI credentials.

## 5. Infrastructure and Application Delivery Are Different Concerns

Terraform manages the platform.

CI/CD manages the application artifact and deployment.

The SSM pointer provides the connection between the two.

This makes it possible to reason about:

``` text
Infrastructure:
Terraform → AWS resources

Application:
Git commit → JAR → S3 → SSM → ASG
```

## 6. Self-Healing Requires Bootstrap Automation

An Auto Scaling Group alone does not guarantee a usable application
instance.

A replacement instance must also be able to:

-   obtain its configuration
-   obtain its artifact
-   start the application
-   pass its health check

The Launch Template user data therefore forms an important part of the
application's resilience design.

## 7. Validate the Real User Path

Infrastructure deployment succeeding is not enough.

The final pipeline validation tests:

``` text
ALB
 ↓
Spring Boot
 ↓
S3
```

using both:

``` text
/health
```

and:

``` text
/documents/test-document.txt
```

This provides a functional validation of the deployed application rather
than only confirming that AWS resources exist.

## 8. Keep Destructive Operations Separate

The normal deployment pipeline should not automatically destroy
infrastructure.

Cleanup is deliberately separate so that:

``` text
Deploy
```

and:

``` text
Destroy
```

remain distinct operational actions.

For a lab environment, this makes the repository safer for other
engineers to clone, deploy, test, and clean up.

## Final Platform Engineering Takeaway

The project evolved from a manually configured application deployment
into a repeatable delivery platform:

``` text
Source Control
      ↓
CI/CD
      ↓
OIDC
      ↓
Immutable Artifact
      ↓
SSM Deployment Pointer
      ↓
Terraform / ASG
      ↓
Self-Bootstrapping EC2
      ↓
ALB
      ↓
Automated Functional Validation
```

The primary goal is not simply to run a Spring Boot application on AWS,
but to demonstrate how an application can be **securely, repeatably, and
automatically delivered and recovered using platform engineering
principles**.
