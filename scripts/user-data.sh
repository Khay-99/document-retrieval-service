#!/bin/bash
# ------------------------------------------------------------------------------------
# Launch-template user data for blueeagle-prod-app-lt (App tier).
#
# Paste this into the "User data" field when you create the blueeagle-prod-app-lt Launch
# Template. Every instance the blueeagle-prod-app-asg Auto Scaling Group launches from this
# template runs this script on first boot. Replace the REPLACE_ME values before saving
# the template. Amazon Linux 2023 is assumed as the base AMI.
#
# What this does on first boot:
#   1. Installs Java 17 and git
#   2. Clones this repository
#   3. Builds the jar with Maven
#   4. Installs it as a systemd service so it survives reboots and instance replacement
#   5. Starts the service
# ------------------------------------------------------------------------------------
set -euo pipefail

GIT_REPO_URL="REPLACE_ME_WITH_YOUR_GITHUB_REPO_URL"
AWS_REGION_VALUE="REPLACE_ME_WITH_YOUR_REGION"
S3_BUCKET_VALUE="REPLACE_ME_WITH_YOUR_BUCKET_NAME"

APP_DIR="/opt/docservice"
BUILD_DIR="/opt/docservice-build"

dnf install -y java-17-amazon-corretto git maven

rm -rf "${BUILD_DIR}"
git clone "${GIT_REPO_URL}" "${BUILD_DIR}"
cd "${BUILD_DIR}"

mvn -q -DskipTests clean package

mkdir -p "${APP_DIR}"
cp target/document-retrieval-service.jar "${APP_DIR}/document-retrieval-service.jar"

cp "${BUILD_DIR}/scripts/docservice.service" /etc/systemd/system/docservice.service
sed -i "s/REPLACE_WITH_YOUR_REGION/${AWS_REGION_VALUE}/" /etc/systemd/system/docservice.service
sed -i "s/REPLACE_WITH_YOUR_BUCKET_NAME/${S3_BUCKET_VALUE}/" /etc/systemd/system/docservice.service

systemctl daemon-reload
systemctl enable docservice
systemctl restart docservice
