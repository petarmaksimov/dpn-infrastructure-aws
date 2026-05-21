locals {
  oidc_provider_hostpath = replace(var.oidc_issuer_url, "https://", "")
}

resource "aws_iam_role" "irsa" {
  for_each = var.service_accounts

  name = "${var.project_name}-${each.key}-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider_hostpath}:aud" = "sts.amazonaws.com"
            "${local.oidc_provider_hostpath}:sub" = "system:serviceaccount:${each.value.namespace}:${each.value.service_account}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "irsa" {
  for_each = var.service_accounts

  name   = "${var.project_name}-${each.key}-${var.environment}"
  policy = each.value.policy_json
}

resource "aws_iam_role_policy_attachment" "irsa" {
  for_each = var.service_accounts

  role       = aws_iam_role.irsa[each.key].name
  policy_arn = aws_iam_policy.irsa[each.key].arn
}
