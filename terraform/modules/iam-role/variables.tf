variable "role_name" {
  description = "Name of the IAM role to create"
  type        = string
}

variable "trust_type" {
  description = "Trust relationship type for the IAM role"
  type        = string
  default     = "ec2"

  validation {
    condition = contains(
      ["github_oidc", "gitlab_oidc", "ec2"],  # Add more allowed trust types here
      var.trust_type
    )

    error_message = "trust_type must be either github_oidc, gitlab_oidc, or ec2."
  }
}

variable "create_oidc_provider" {
  description = "Create the GitHub OIDC provider when using GitHub OIDC trust"
  type        = bool
  default     = false
}

variable "github_oidc_subjects" {
  description = "GitHub OIDC subject patterns allowed to assume the role"
  type        = list(string)
  default     = []

  validation {
    condition = (
      var.trust_type != "github_oidc"
      || length(var.github_oidc_subjects) > 0
    )

    error_message = "github_oidc_subjects must contain at least one subject when trust_type is github_oidc."
  }
}

variable "gitlab_oidc_subjects" {
  description = "GitLab OIDC subject patterns allowed to assume the role"
  type        = list(string)
  default     = []

  validation {
    condition = (
      var.trust_type != "gitlab_oidc"
      || length(var.gitlab_oidc_subjects) > 0
    )
    error_message = "gitlab_oidc_subjects must contain at least one subject when trust_type is gitlab_oidc."
  }
}

variable "gitlab_project_id" {
  description = "GitLab project ID allowed to assume the role"
  type        = string
  default     = ""

  validation {
    condition = (
      var.trust_type != "gitlab_oidc"
      || length(var.gitlab_project_id) > 0
    )
    error_message = "gitlab_project_id must be provided when trust_type is gitlab_oidc."
  }
}

variable "gitlab_oidc_thumbprint" {
  description = "Thumbprint of the GitLab OIDC provider"
  type        = string
  default     = ""
}

variable "github_oidc_thumbprint" {
  description = "Thumbprint of the GitHub OIDC provider"
  type        = string
  default     = ""
}

variable "managed_policy_arns" {
  description = "List of managed policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

variable "inline_policy_statements" {
  description = "IAM policy statements to attach to the role"

  type = list(object({
    Sid      = string
    Effect   = string
    Action   = list(string)
    Resource = list(string)
  }))

  default = []
}

variable "tags" {
  description = "Tags to apply to IAM resources"
  type        = map(string)
  default     = {}
}