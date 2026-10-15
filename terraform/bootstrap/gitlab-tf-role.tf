module "gitlab_ci_tf_role" {
  source = "../modules/iam-role"

  role_name  = "gitlab-ci-tf-role"
  trust_type = "gitlab_oidc"

  create_oidc_provider = false

  gitlab_project_id = "85917214"

  gitlab_oidc_subjects = [
    "project_path:wandaprep/document-retrieval-service:ref_type:branch:ref:*"
  ]

  gitlab_oidc_thumbprint = "3C4A8B66430EDDE6B6F03FD431E01A5E30FCE540"

  managed_policy_arns = [
  ]

  inline_policy_statements = [

    # ============================================================
    # APPLICATION DEPLOYMENT PERMISSIONS
    # ============================================================

    {
      Sid    = "AllowArtifactUpload"
      Effect = "Allow"
      Action = [
        "s3:PutObject"
      ]
      Resource = [
        "arn:aws:s3:::blueeagle-prod-app-doc-artifacts/document-retrieval-service/*"
      ]
    },

    {
      Sid    = "AllowUpdateArtifactPointer"
      Effect = "Allow"
      Action = [
        "ssm:PutParameter"
      ]
      Resource = [
        "arn:aws:ssm:us-east-1:651706774390:parameter/blueeagle/prod/document-retrieval-service/artifact-key"
      ]
    },

    {
      Sid    = "AllowAsgDeployment"
      Effect = "Allow"
      Action = [
        "autoscaling:StartInstanceRefresh",
        "autoscaling:DescribeInstanceRefreshes",
        "autoscaling:DescribeAutoScalingGroups"
      ]
      Resource = [
        "*"
      ]
    },

    # ============================================================
    # TERRAFORM INFRASTRUCTURE PERMISSIONS
    # ============================================================

    # VPC / Networking
    {
      Sid    = "AllowVpcNetworking"
      Effect = "Allow"
      Action = [
        "ec2:CreateVpc",
        "ec2:DeleteVpc",
        "ec2:DescribeVpcs",
        "ec2:ModifyVpcAttribute",
        "ec2:CreateSubnet",
        "ec2:DeleteSubnet",
        "ec2:DescribeSubnets",
        "ec2:ModifySubnetAttribute",
        "ec2:CreateRouteTable",
        "ec2:DeleteRouteTable",
        "ec2:DescribeRouteTables",
        "ec2:AssociateRouteTable",
        "ec2:DisassociateRouteTable",
        "ec2:CreateRoute",
        "ec2:ReplaceRoute",
        "ec2:DeleteRoute",
        "ec2:DescribeRouteTables",
        "ec2:CreateInternetGateway",
        "ec2:DeleteInternetGateway",
        "ec2:AttachInternetGateway",
        "ec2:DetachInternetGateway",
        "ec2:DescribeInternetGateways",
        "ec2:CreateNatGateway",
        "ec2:DeleteNatGateway",
        "ec2:DescribeNatGateways",
        "ec2:AllocateAddress",
        "ec2:ReleaseAddress",
        "ec2:DescribeAddresses",
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:DescribeSecurityGroups",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:CreateTags",
        "ec2:DeleteTags",
        "ec2:DescribeTags",
        "ec2:DescribeVpcAttribute",
        "ec2:DescribeNetworkInterfaces"
      ]
      Resource = [
        "*"
      ]
    },

    # EC2 / Launch Templates
    {
      Sid    = "AllowEc2Infrastructure"
      Effect = "Allow"
      Action = [
        "ec2:RunInstances",
        "ec2:TerminateInstances",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus",
        "ec2:DescribeImages",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeAvailabilityZones",
        "ec2:CreateLaunchTemplate",
        "ec2:CreateLaunchTemplateVersion",
        "ec2:ModifyLaunchTemplate",
        "ec2:DeleteLaunchTemplate",
        "ec2:DeleteLaunchTemplateVersions",
        "ec2:DescribeLaunchTemplates",
        "ec2:DescribeLaunchTemplateVersions"
      ]
      Resource = [
        "*"
      ]
    },

    # Auto Scaling
    {
      Sid    = "AllowAutoScalingInfrastructure"
      Effect = "Allow"
      Action = [
        "autoscaling:CreateAutoScalingGroup",
        "autoscaling:UpdateAutoScalingGroup",
        "autoscaling:DeleteAutoScalingGroup",
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeScalingActivities",
        "autoscaling:PutScalingPolicy",
        "autoscaling:DeletePolicy",
        "autoscaling:DescribePolicies",
        "autoscaling:AttachLoadBalancerTargetGroups",
        "autoscaling:DetachLoadBalancerTargetGroups",
        "autoscaling:StartInstanceRefresh",
        "autoscaling:CancelInstanceRefresh",
        "autoscaling:DescribeInstanceRefreshes",
        "autoscaling:SetDesiredCapacity"
      ]
      Resource = [
        "*"
      ]
    },

    # ALB / Target Groups / Listeners
    {
      Sid    = "AllowAlbInfrastructure"
      Effect = "Allow"
      Action = [
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:DeleteTargetGroup",
        "elasticloadbalancing:ModifyTargetGroup",
        "elasticloadbalancing:ModifyTargetGroupAttributes",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:ModifyListener",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:CreateRule",
        "elasticloadbalancing:DeleteRule",
        "elasticloadbalancing:ModifyRule",
        "elasticloadbalancing:DescribeRules",
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:RemoveTags",
        "elasticloadbalancing:DescribeTags",
        "elasticloadbalancing:DescribeLoadBalancerAttributes",
        "elasticloadbalancing:DescribeTargetGroupAttributes",
        "elasticloadbalancing:DescribeListenerAttributes",
        "elasticloadbalancing:DescribeTargetHealth"
      ]
      Resource = [
        "*"
      ]
    },

    # IAM Roles / Policies / Instance Profiles
    {
      Sid    = "AllowIamInfrastructure"
      Effect = "Allow"
      Action = [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:UpdateRole",
        "iam:UpdateAssumeRolePolicy",
        "iam:TagRole",
        "iam:UntagRole",
        "iam:CreatePolicy",
        "iam:DeletePolicy",
        "iam:GetPolicy",
        "iam:GetPolicyVersion",
        "iam:CreatePolicyVersion",
        "iam:DeletePolicyVersion",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:GetRolePolicy",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:CreateInstanceProfile",
        "iam:DeleteInstanceProfile",
        "iam:GetInstanceProfile",
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:TagInstanceProfile",
        "iam:UntagInstanceProfile",
        "iam:PassRole"
      ]
      Resource = [
        "*"
      ]
    },

    # S3 infrastructure
    {
      Sid    = "AllowS3Infrastructure"
      Effect = "Allow"
      Action = [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:GetBucketLocation",
        "s3:GetBucketVersioning",
        "s3:PutBucketVersioning",
        "s3:GetBucketTagging",
        "s3:PutBucketTagging",
        "s3:GetBucketPolicy",
        "s3:PutBucketPolicy",
        "s3:DeleteBucketPolicy",
        "s3:GetBucketPublicAccessBlock",
        "s3:PutBucketPublicAccessBlock",
        "s3:GetBucketEncryption",
        "s3:PutBucketEncryption",
        "s3:GetLifecycleConfiguration",
        "s3:PutLifecycleConfiguration",
        "s3:DeleteBucket",
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ]
      Resource = [
        "*"
      ]
    },

    # CloudWatch / SNS
    {
      Sid    = "AllowCloudWatchSnsInfrastructure"
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:DeleteLogGroup",
        "logs:DescribeLogGroups",
        "logs:PutRetentionPolicy",
        "logs:DeleteRetentionPolicy",
        "logs:TagResource",
        "logs:UntagResource",
        "cloudwatch:PutMetricAlarm",
        "cloudwatch:DeleteAlarms",
        "cloudwatch:DescribeAlarms",
        "cloudwatch:TagResource",
        "sns:CreateTopic",
        "sns:DeleteTopic",
        "sns:GetTopicAttributes",
        "sns:SetTopicAttributes",
        "sns:Subscribe",
        "sns:Unsubscribe",
        "sns:ListSubscriptionsByTopic",
        "sns:TagResource",
        "sns:UntagResource"
      ]
      Resource = [
        "*"
      ]
    },

    # SSM infrastructure
    {
      Sid    = "AllowSsmInfrastructure"
      Effect = "Allow"
      Action = [
        "ssm:CreateParameter",
        "ssm:DeleteParameter",
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParameterHistory",
        "ssm:PutParameter",
        "ssm:AddTagsToResource",
        "ssm:RemoveTagsFromResource",
        "ssm:ListTagsForResource"
      ]
      Resource = [
        "*"
      ]
    }
  ]

  tags = {
    Project = "document-retrieval-service-app"
    Owner   = "wandaprep"
  }
}

