# Troubleshooting

## ALB Returns 502

A `502 Bad Gateway` from the ALB usually means the ALB cannot
successfully connect to a healthy application target.

Check target health:

``` bash
TG_ARN=$(aws elbv2 describe-target-groups \
  --names "blueeagle-prod-app-tg" \
  --region us-east-1 \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

aws elbv2 describe-target-health \
  --target-group-arn "$TG_ARN" \
  --region us-east-1 \
  --query 'TargetHealthDescriptions[].{Instance:Target.Id,Port:Target.Port,State:TargetHealth.State,Reason:TargetHealth.Reason,Description:TargetHealth.Description}' \
  --output table
```

Then check the application on the instance:

``` bash
sudo systemctl status docservice --no-pager
```

``` bash
curl -v http://localhost:8080/health
```

If localhost fails, the issue is on the instance rather than the ALB.

## `docservice.service` Does Not Exist

Check whether cloud-init completed successfully:

``` bash
cloud-init status --long
```

Review bootstrap output:

``` bash
sudo cat /var/log/cloud-init-output.log
```

Inspect the user-data script executed by cloud-init:

``` bash
sudo sed -n '1,240p' /var/lib/cloud/instance/scripts/part-001
```

The user-data script is responsible for preparing the instance,
retrieving the deployment pointer, downloading the application artifact,
and configuring the service.

## SSM Parameter Not Found

Check the deployment pointer:

``` bash
aws ssm get-parameter \
  --name "/blueeagle/prod/document-retrieval-service/artifact-key" \
  --region us-east-1 \
  --query 'Parameter.Value' \
  --output text
```

If the parameter does not exist, the ASG should not be refreshed yet.

The correct sequence is:

``` text
Publish artifact
      |
      v
Create/update SSM pointer
      |
      v
Refresh ASG
```

Starting the refresh before the pointer exists can cause new instances
to fail during bootstrap.

## Verify the Referenced Artifact

Retrieve the pointer:

``` bash
ARTIFACT_KEY=$(aws ssm get-parameter \
  --name "/blueeagle/prod/document-retrieval-service/artifact-key" \
  --region us-east-1 \
  --query 'Parameter.Value' \
  --output text)
```

Then verify the object:

``` bash
aws s3api head-object \
  --bucket "blueeagle-prod-app-doc-artifacts" \
  --key "$ARTIFACT_KEY" \
  --region us-east-1
```

## Application Runs but Document Retrieval Fails

Check the effective application configuration:

``` bash
sudo systemctl cat docservice
```

The service requires the correct:

``` text
AWS_REGION
S3_BUCKET_NAME
```

Then verify the instance role can access the document bucket.

Also test locally on the instance:

``` bash
curl -v http://localhost:8080/documents/test-document.txt
```

## Useful Runtime Commands

``` bash
sudo systemctl status docservice --no-pager
```

``` bash
sudo journalctl -u docservice -n 100 --no-pager
```

``` bash
sudo systemctl restart docservice
```

``` bash
curl http://localhost:8080/health
```

## Important Diagnostic Principle

Troubleshoot from the inside out:

``` text
Spring Boot
    ↓
EC2
    ↓
Target Group
    ↓
ALB
    ↓
Client
```

If `localhost:8080/health` fails, do not start with the ALB. Fix the
application/bootstrap problem first.
