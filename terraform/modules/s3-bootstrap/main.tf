resource "aws_s3_bucket" "bootstrap" {
  bucket = var.bucket_name

  tags = merge(
    var.tags,
    {
      Name = var.bucket_name
    }
  )
}


# ------------------------------------------------------------
# Versioning
# ------------------------------------------------------------

resource "aws_s3_bucket_versioning" "bootstrap_versioning" {
  bucket = aws_s3_bucket.bootstrap.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}


# ------------------------------------------------------------
# Encryption
# ------------------------------------------------------------

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.bootstrap.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn
    }

    bucket_key_enabled = var.kms_key_arn != null
  }
}


# ------------------------------------------------------------
# Block ALL public access
# ------------------------------------------------------------

resource "aws_s3_bucket_public_access_block" "bootstrap_public_access_block" {
  bucket = aws_s3_bucket.bootstrap.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# ------------------------------------------------------------
# Ownership controls
# ------------------------------------------------------------

resource "aws_s3_bucket_ownership_controls" "bootstrap_ownership_controls" {
  bucket = aws_s3_bucket.bootstrap.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}


# ------------------------------------------------------------
# Lifecycle management
# ------------------------------------------------------------

resource "aws_s3_bucket_lifecycle_configuration" "bootstrap_lifecycle" {
  count = var.enable_lifecycle && var.enable_versioning ? 1 : 0

  bucket = aws_s3_bucket.bootstrap.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }
  }
}