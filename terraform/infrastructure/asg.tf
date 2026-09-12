module "asg" {
  source = "../modules/asg"

  subnet_ids                = module.vpc.vpc_public_subnets
  web_sg_id                 = module.web_sg.web_sg_id
  ec2_role_name             = "ec2-tf-role"  #update with existing IAM role name
  ami_id                    = "ami-08b5b3a93ed654d19"
  instance_type             = "t2.micro"
  key_name                  = "us-east-1-musty"
  user_data = templatefile(
    "${path.module}/../../scripts/user-data.sh",
    {
      git_repo_url   = "https://github.com/dainmusty/document-retrieval-service-test.git"
      aws_region     = "us-east-1"
      artifact_bucket_name = "blueeagle-prod-app-doc-artifacts"
      document_bucket_name = "blueeagle-prod-app-documents"
    }
  )

  launch_template_name = "blueeagle-prod-app-lt"
  asg_name             = "blueeagle-prod-app-asg"
  min_size              = 1
  max_size              = 2
  desired_capacity      = 1
  
  target_group_arn          = module.alb.target_group_arn
}
