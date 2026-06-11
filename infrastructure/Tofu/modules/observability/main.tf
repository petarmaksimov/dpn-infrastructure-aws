locals {
  name_prefix = "${var.project_name}-${var.environment}"

  bucket_names = {
    alb      = "${var.project_name}-alb-logs-${var.environment}-${data.aws_caller_identity.current.account_id}"
    firewall = "${var.project_name}-nfw-logs-${var.environment}-${data.aws_caller_identity.current.account_id}"
    ssm      = "${var.project_name}-ssm-logs-${var.environment}-${data.aws_caller_identity.current.account_id}"
  }
}

resource "aws_cloudwatch_log_group" "vpc_flow" {
  name              = "/aws/vpc/flow/${local.name_prefix}"
  retention_in_days = var.log_retention_in_days

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "firewall_flow" {
  name              = "/aws/network-firewall/flow/${local.name_prefix}"
  retention_in_days = var.log_retention_in_days

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "firewall_alert" {
  name              = "/aws/network-firewall/alert/${local.name_prefix}"
  retention_in_days = var.log_retention_in_days

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "eks_control_plane" {
  name              = "/aws/eks/control-plane/${local.name_prefix}"
  retention_in_days = var.log_retention_in_days

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "ssm_sessions" {
  name              = "/aws/ssm/sessions/${local.name_prefix}"
  retention_in_days = var.log_retention_in_days

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "waf" {
  name              = "aws-waf-logs-${local.name_prefix}"
  retention_in_days = var.log_retention_in_days

  tags = var.tags
}

resource "aws_s3_bucket" "alb_logs" {
  count  = var.create_log_s3_buckets ? 1 : 0
  bucket = local.bucket_names.alb

  tags = var.tags
}

resource "aws_s3_bucket" "firewall_logs" {
  count  = var.create_log_s3_buckets ? 1 : 0
  bucket = local.bucket_names.firewall

  tags = var.tags
}

resource "aws_s3_bucket" "ssm_logs" {
  count  = var.create_log_s3_buckets ? 1 : 0
  bucket = local.bucket_names.ssm

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "alb_logs" {
  count  = var.create_log_s3_buckets ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "firewall_logs" {
  count  = var.create_log_s3_buckets ? 1 : 0
  bucket = aws_s3_bucket.firewall_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "ssm_logs" {
  count  = var.create_log_s3_buckets ? 1 : 0
  bucket = aws_s3_bucket.ssm_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  count  = var.create_log_s3_buckets ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "firewall_logs" {
  count  = var.create_log_s3_buckets ? 1 : 0
  bucket = aws_s3_bucket.firewall_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ssm_logs" {
  count  = var.create_log_s3_buckets ? 1 : 0
  bucket = aws_s3_bucket.ssm_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  count                   = var.create_log_s3_buckets ? 1 : 0
  bucket                  = aws_s3_bucket.alb_logs[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "firewall_logs" {
  count                   = var.create_log_s3_buckets ? 1 : 0
  bucket                  = aws_s3_bucket.firewall_logs[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "ssm_logs" {
  count                   = var.create_log_s3_buckets ? 1 : 0
  bucket                  = aws_s3_bucket.ssm_logs[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}