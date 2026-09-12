output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.bootstrap.bucket
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.bootstrap.arn
}

output "bucket_id" {
  description = "S3 bucket ID"
  value       = aws_s3_bucket.bootstrap.id
}