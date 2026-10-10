provider "aws" {
  region = "us-east-1"
}

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "github_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repository_username}*/${var.github_repository_name}*:*"]
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy_attachment" "lambda_full" {
  role       = aws_iam_role.github_oidc.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}

# Lets the pipeline create the Lambda's execution role, limited to roles named kean-*
resource "aws_iam_role_policy" "manage_lambda_role" {
  name = "kean-manage-lambda-role"
  role = aws_iam_role.github_oidc.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "iam:CreateRole", "iam:DeleteRole", "iam:GetRole", "iam:TagRole", "iam:UntagRole",
        "iam:UpdateAssumeRolePolicy", "iam:PassRole",
        "iam:AttachRolePolicy", "iam:DetachRolePolicy",
        "iam:ListAttachedRolePolicies", "iam:ListRolePolicies", "iam:ListInstanceProfilesForRole"
      ]
      Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/kean-*"
    }]
  })
}

resource "aws_iam_role" "github_oidc" {
  name               = var.github_oidc_role_name
  assume_role_policy = data.aws_iam_policy_document.github_trust.json
}

resource "aws_iam_role_policy_attachment" "s3_full" {
  role       = aws_iam_role.github_oidc.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

variable "github_repository_username" {
  description = "GitHub repository username"
  type        = string
}

variable "github_repository_name" {
  description = "GitHub repository name"
  type        = string
}

variable "github_oidc_role_name" {
  description = "Name of the GitHub OIDC role"
  type        = string
}

output "github_oidc_role_arn" {
  value = aws_iam_role.github_oidc.arn
}