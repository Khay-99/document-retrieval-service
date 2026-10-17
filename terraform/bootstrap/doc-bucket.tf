module "document_bucket" {
  source = "../modules/s3-bootstrap"

  bucket_name = "blueeagle-prod-app-documents"

  enable_versioning = true
  enable_lifecycle  = true

  # 90 days is just a starting point.
  # We can tune this later based on the company's
  # state-retention requirements.
  noncurrent_version_expiration_days = 90

  tags = {
    Environment = "prod"
    Application = "blueeagle"
    Purpose     = "documents-bucket"
    ManagedBy   = "terraform"
  }
}

