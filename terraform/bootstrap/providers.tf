provider "aws" {
  region = "us-east-1"

}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.82"
    }
  }
}


terraform {
  required_version = ">= 1.5.0"
}

