##############################
# GitLab OIDC provider
##############################

resource "aws_iam_openid_connect_provider" "gitlab" {
  count = var.trust_type == "gitlab_oidc" && var.create_oidc_provider ? 1 : 0

  url = "https://gitlab.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    var.gitlab_oidc_thumbprint
  ]

  tags = var.tags
}

##############################
# GitLab OIDC provider ARN
##############################

locals {
  gitlab_oidc_provider_arn = (
    var.trust_type == "gitlab_oidc" && var.create_oidc_provider
    ? aws_iam_openid_connect_provider.gitlab[0].arn
    : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/gitlab.com"
  )
}

##############################
# GitLab OIDC trust policy
##############################

locals {
  gitlab_oidc_assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Federated = local.gitlab_oidc_provider_arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "gitlab.com:aud"        = "sts.amazonaws.com"
            "gitlab.com:project_id" = var.gitlab_project_id
          }

          StringLike = {
            "gitlab.com:sub" = var.gitlab_oidc_subjects
          }
        }
      }
    ]
  })
}
