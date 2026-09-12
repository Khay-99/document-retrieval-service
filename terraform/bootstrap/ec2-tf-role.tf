module "ec2_tf_role" {
  source = "../modules/iam-role"

  role_name = "ec2-tf-role"

  trust_type = "ec2"


  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AdministratorAccess"  # This is for testing purposes only. Remove this in production.
  ]
  inline_policy_statements = [
    {
      Sid    = "AllowReadApplicationArtifact"
      Effect = "Allow"

      Action = [
        "s3:GetObject"
      ]

      Resource = [
        "arn:aws:s3:::blueeagle-prod-app-documents/document-retrieval-service/*"
      ]
    },
    {
      Sid    = "AllowListDocuments"
      Effect = "Allow"
      Action = [
        "s3:ListBucket"
      ]
      Resource = [
        "arn:aws:s3:::blueeagle-prod-app-documents"
      ]
    },
    {
      Sid    = "AllowReadDocuments"
      Effect = "Allow"
      Action = [
        "s3:GetObject"
      ]
      Resource = [
        "arn:aws:s3:::blueeagle-prod-app-documents/*"
      ]
    },
    {
      Sid    = "AllowReadArtifactParameter"
      Effect = "Allow"

      Action = [
        "ssm:GetParameter"
      ]

      Resource = [
        "arn:aws:ssm:us-east-1:651706774390:parameter/blueeagle/prod/document-retrieval-service/artifact-key"
      ]
    }
  ]

  tags = {
    Project = "document-retrieval-service-app"
    Owner   = "wandaprep"
  }
}