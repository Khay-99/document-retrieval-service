terraform {
  backend "s3" {
    bucket         = "blueeagle-prod-app-state-bucket"
    key            = "infra/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    use_lockfile = true
    # Native s3 locking!
  }
}
