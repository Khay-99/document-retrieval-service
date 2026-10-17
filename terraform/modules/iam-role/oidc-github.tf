##############################
# GitHub OIDC provider
##############################

resource "aws_iam_openid_connect_provider" "github" {
  count = var.trust_type == "github_oidc" && var.create_oidc_provider ? 1 : 0

  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    var.github_oidc_thumbprint
  ]

  tags = var.tags
}

##############################
# GitHub OIDC provider ARN
##############################

locals {
  github_oidc_provider_arn = (
  var.trust_type == "github_oidc" && var.create_oidc_provider
  ? aws_iam_openid_connect_provider.github[0].arn
  : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
)
}

##############################
# Trust policies + Shared role selection
##############################

locals {
  github_oidc_assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Federated = local.github_oidc_provider_arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }

          StringLike = {
            "token.actions.githubusercontent.com:sub" = var.github_oidc_subjects
          }
        }
      }
    ]
  })

  ec2_assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

 assume_role_policy = (
  var.trust_type == "github_oidc" ? local.github_oidc_assume_role_policy :
  var.trust_type == "gitlab_oidc"  ? local.gitlab_oidc_assume_role_policy :
  local.ec2_assume_role_policy
)
}