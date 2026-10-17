output "github_actions_role_name" {
  value = aws_iam_role.bootstrap_role.name
}

output "service_role_arn" {
  value = aws_iam_role.bootstrap_role.arn
}

output "inline_policy_arns" {
  value = aws_iam_policy.inline.arn
  }


