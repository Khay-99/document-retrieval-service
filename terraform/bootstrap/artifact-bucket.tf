
# ------------------------------------------------------------
# Application artifact bucket
# ------------------------------------------------------------

module "artifact_bucket" {
  source = "../modules/s3-bootstrap"

  bucket_name = "blueeagle-prod-app-doc-artifacts"

  enable_versioning = true
  enable_lifecycle  = true

  noncurrent_version_expiration_days = 90

  tags = {
    Environment = "prod"
    Application = "blueeagle"
    Purpose     = "document-artifacts"
    ManagedBy   = "terraform"
  }
}