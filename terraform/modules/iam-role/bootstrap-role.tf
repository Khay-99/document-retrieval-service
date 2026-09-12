
##############################
# IAM role
##############################

resource "aws_iam_role" "bootstrap_role" {
  name = var.role_name

  assume_role_policy = local.assume_role_policy

  tags = var.tags
}


##############################
# Inline policy
##############################

resource "aws_iam_policy" "inline" {
  name = "${var.role_name}-policy"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      for st in var.inline_policy_statements : {
        Sid      = st.Sid
        Effect   = st.Effect
        Action   = st.Action
        Resource = st.Resource
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_inline" {
  role       = aws_iam_role.bootstrap_role.name
  policy_arn = aws_iam_policy.inline.arn
}

##############################
# Managed policy attachments
##############################

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.bootstrap_role.name
  policy_arn = each.key
}