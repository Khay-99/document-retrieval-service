#!/bin/bash
# EC2 Launch Template user-data for blueeagle-prod-app-lt.
# Installs Java 17, builds document-retrieval-service from source, and
# installs it as a systemd service. Every instance the app-tier Auto
# Scaling Group launches runs this same script - there is no golden AMI to
# keep in sync, the source of truth is this repository.

set -euo pipefail

AWS_REGION="__AWS_REGION__"
S3_BUCKET_NAME="__S3_BUCKET_NAME__"
REPO_URL="https://gitlab.com/wandaprep/document-retrieval-service.git"
BUILD_DIR="/opt/build/document-retrieval-service"
INSTALL_DIR="/opt/docservice"

yum update -y
yum install -y java-17-amazon-corretto git maven

id -u docservice &>/dev/null || useradd -r -s /sbin/nologin docservice

rm -rf "$BUILD_DIR"
git clone "$REPO_URL" "$BUILD_DIR"
cd "$BUILD_DIR"
mvn -q clean package -DskipTests

mkdir -p "$INSTALL_DIR"
cp target/document-retrieval-service.jar "$INSTALL_DIR/document-retrieval-service.jar"
chown -R docservice:docservice "$INSTALL_DIR"

sed \
  -e "s/__AWS_REGION__/${AWS_REGION}/" \
  -e "s/__S3_BUCKET_NAME__/${S3_BUCKET_NAME}/" \
  "$BUILD_DIR/scripts/docservice.service" > /etc/systemd/system/docservice.service

systemctl daemon-reload
systemctl enable docservice
systemctl restart docservice
