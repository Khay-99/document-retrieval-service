# module "ec2" {
#   source = "../modules/ec2"

#   ResourcePrefix     = "Dev"
#   ami_id             = "ami-081b0a6eac00b4f53"
#   instance_name      = "AL2023-1"
#   instance_type      = "t2.micro"
#   key_name           = "us-east-1-musty"
#   volume_size        = 8
#   volume_type        = "gp2"
#   admin_profile_name = module.iam.instance_profile_name

#   subnet_id         = module.vpc.vpc_public_subnets[0]
#   security_group_id = module.web_sg.web_sg_id
#   user_data = templatefile(
#     "${path.module}/../../scripts/user-data.sh",
#     {
#       git_repo_url   = "https://github.com/dainmusty/document-retrieval-service-test.git"
#       aws_region     = "us-east-1"
#       s3_bucket_name = "mustydain"
#     }
#   )

#   additional_tags = {
#     role        = "users"
#     Environment = "Dev"
#   }

#   instance_scope = "public"
# }
