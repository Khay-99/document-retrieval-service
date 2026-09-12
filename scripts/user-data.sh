#!/bin/bash
set -e

exec > >(tee /var/log/docservice-user-data.log | logger -t docservice-user-data -s 2>/dev/console) 2>&1

echo "=== BlueEagle Document Retrieval Service bootstrap ==="

APP_DIR="/opt/docservice"

# Terraform template variables
AWS_REGION="${aws_region}"
ARTIFACT_BUCKET="${artifact_bucket_name}"
DOCUMENT_BUCKET="${document_bucket_name}"
ARTIFACT_PARAMETER="/blueeagle/prod/document-retrieval-service/artifact-key"

echo "AWS Region: $${AWS_REGION}"
echo "Artifact Bucket: $${ARTIFACT_BUCKET}"
echo "Document Bucket: $${DOCUMENT_BUCKET}"
echo "Artifact Parameter: $${ARTIFACT_PARAMETER}"

echo "Installing required packages..."
dnf install -y java-17-amazon-corretto awscli

echo "Creating application directory..."
mkdir -p "$${APP_DIR}"
chown -R ec2-user:ec2-user "$${APP_DIR}"

echo "Reading artifact pointer from SSM..."

ARTIFACT_KEY=$(aws ssm get-parameter \
  --name "$${ARTIFACT_PARAMETER}" \
  --region "$${AWS_REGION}" \
  --query 'Parameter.Value' \
  --output text)

if [ -z "$${ARTIFACT_KEY}" ] || [ "$${ARTIFACT_KEY}" = "None" ]; then
  echo "ERROR: Artifact pointer was not found in SSM."
  exit 1
fi

echo "Artifact key: $${ARTIFACT_KEY}"

echo "Downloading exact artifact from S3..."

aws s3 cp \
  "s3://$${ARTIFACT_BUCKET}/$${ARTIFACT_KEY}" \
  "$${APP_DIR}/document-retrieval-service.jar" \
  --region "$${AWS_REGION}"

echo "Verifying downloaded artifact..."

if [ ! -f "$${APP_DIR}/document-retrieval-service.jar" ]; then
  echo "ERROR: Application JAR was not downloaded."
  exit 1
fi

chown ec2-user:ec2-user "$${APP_DIR}/document-retrieval-service.jar"

echo "Creating systemd service..."

cat > /etc/systemd/system/docservice.service <<SERVICE
[Unit]
Description=BlueEagle Document Retrieval Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/docservice

Environment="AWS_REGION=$${AWS_REGION}"
Environment="S3_BUCKET_NAME=$${ARTIFACT_BUCKET}"
Environment="S3_BUCKET_NAME=$${DOCUMENT_BUCKET}"

ExecStart=/usr/bin/java -jar /opt/docservice/document-retrieval-service.jar

Restart=always
RestartSec=5
SuccessExitStatus=143

[Install]
WantedBy=multi-user.target
SERVICE

echo "Starting application..."

systemctl daemon-reload
systemctl enable docservice
systemctl restart docservice

echo "Waiting for application to start..."
sleep 10

echo "Checking application health..."

curl -f http://localhost:8080/health

echo ""
echo "=== Bootstrap completed successfully ==="

systemctl --no-pager status docservice