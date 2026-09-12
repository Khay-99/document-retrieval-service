# # VPC Module
module "vpc" {
  source = "../modules/vpc"

  vpc_cidr                      = "10.1.0.0/16"
  ResourcePrefix                = "blueeagle-prod-app"
  enable_dns_hostnames          = true
  enable_dns_support            = true
  instance_tenancy              = "default"
  public_subnet_cidr            = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidr           = ["10.1.3.0/24", "10.1.4.0/24"]
  availability_zones            = ["us-east-1a", "us-east-1b"]
  public_ip_on_launch           = true
  PublicRT_cidr                 = "0.0.0.0/0"
  PrivateRT_cidr                = "0.0.0.0/0"
  eip_associate_with_private_ip = false
}
