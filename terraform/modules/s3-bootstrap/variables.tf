variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "enable_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "enable_lifecycle" {
  description = "Enable lifecycle management for old object versions"
  type        = bool
  default     = true
}

variable "noncurrent_version_expiration_days" {
  description = "Number of days before noncurrent object versions are permanently deleted"
  type        = number
  default     = 90
}

variable "kms_key_arn" {
  description = "Optional customer-managed KMS key ARN"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the bucket"
  type        = map(string)
  default     = {}
}