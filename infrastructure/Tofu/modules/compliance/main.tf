data "aws_caller_identity" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  cloudtrail_bucket = "${var.project_name}-cloudtrail-${var.environment}-${data.aws_caller_identity.current.account_id}"
  config_bucket     = "${var.project_name}-config-${var.environment}-${data.aws_caller_identity.current.account_id}"
}

resource "aws_ssm_document" "session_manager_preferences" {
  count = var.enable_session_manager_preferences ? 1 : 0

  name            = "ssm-session-preferences-${local.name_prefix}"
  document_type   = "Session"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "1.0"
    description   = "Session Manager preferences for ${local.name_prefix}"
    sessionType   = "Standard_Stream"
    inputs = {
      cloudWatchLogGroupName      = var.ssm_sessions_log_group_name
      cloudWatchEncryptionEnabled = true
      s3BucketName                = var.ssm_logs_bucket_name
      s3KeyPrefix                 = "ssm-sessions"
      s3EncryptionEnabled         = true
      kmsKeyId                    = var.kms_key_arn
      runAsEnabled                = true
      runAsDefaultUser            = var.ssm_run_as_default_user
      idleSessionTimeout          = tostring(var.ssm_idle_session_timeout_minutes)
      maxSessionDuration          = tostring(var.ssm_max_session_duration_minutes)
    }
  })

  tags = var.tags
}

resource "aws_guardduty_detector" "this" {
  count  = var.enable_guardduty ? 1 : 0
  enable = true

  tags = var.tags
}

resource "aws_securityhub_account" "this" {
  count = var.enable_security_hub ? 1 : 0
}

resource "aws_s3_bucket" "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = local.cloudtrail_bucket

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail[0].arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail[0].arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "this" {
  count = var.enable_cloudtrail ? 1 : 0

  name                          = "trail-${local.name_prefix}"
  s3_bucket_name                = aws_s3_bucket.cloudtrail[0].bucket
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  kms_key_id                    = var.kms_key_arn

  depends_on = [aws_s3_bucket_policy.cloudtrail]

  tags = var.tags
}

resource "aws_s3_bucket" "config" {
  count  = var.enable_aws_config ? 1 : 0
  bucket = local.config_bucket

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "config" {
  count  = var.enable_aws_config ? 1 : 0
  bucket = aws_s3_bucket.config[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config" {
  count  = var.enable_aws_config ? 1 : 0
  bucket = aws_s3_bucket.config[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "config" {
  count  = var.enable_aws_config ? 1 : 0
  bucket = aws_s3_bucket.config[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "config" {
  count  = var.enable_aws_config ? 1 : 0
  bucket = aws_s3_bucket.config[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSConfigBucketPermissionsCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = [
          "s3:GetBucketAcl",
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.config[0].arn
      },
      {
        Sid    = "AWSConfigBucketDelivery"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.config[0].arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "config" {
  count = var.enable_aws_config ? 1 : 0

  name = "iam-${var.project_name}-config-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "config_managed" {
  count = var.enable_aws_config ? 1 : 0

  role       = aws_iam_role.config[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_config_configuration_recorder" "this" {
  count = var.enable_aws_config ? 1 : 0

  name     = "default"
  role_arn = aws_iam_role.config[0].arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "this" {
  count = var.enable_aws_config ? 1 : 0

  name           = "default"
  s3_bucket_name = aws_s3_bucket.config[0].bucket

  depends_on = [
    aws_config_configuration_recorder.this,
    aws_s3_bucket_policy.config
  ]
}

resource "aws_config_configuration_recorder_status" "this" {
  count = var.enable_aws_config ? 1 : 0

  name       = aws_config_configuration_recorder.this[0].name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.this]
}

resource "aws_config_config_rule" "ec2_imdsv2_check" {
  count = var.enable_aws_config ? 1 : 0

  name = "ec2-imdsv2-check"
  source {
    owner             = "AWS"
    source_identifier = "EC2_IMDSV2_CHECK"
  }

  depends_on = [aws_config_configuration_recorder_status.this]
}

resource "aws_config_config_rule" "eks_endpoint_no_public_access" {
  count = var.enable_aws_config ? 1 : 0

  name = "eks-endpoint-no-public-access"
  source {
    owner             = "AWS"
    source_identifier = "EKS_ENDPOINT_NO_PUBLIC_ACCESS"
  }

  depends_on = [aws_config_configuration_recorder_status.this]
}

resource "aws_config_config_rule" "restricted_ssh" {
  count = var.enable_aws_config ? 1 : 0

  name = "restricted-ssh"
  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }

  depends_on = [aws_config_configuration_recorder_status.this]
}

resource "aws_config_config_rule" "rds_public_access" {
  count = var.enable_aws_config ? 1 : 0

  name = "rds-instance-public-access-check"
  source {
    owner             = "AWS"
    source_identifier = "RDS_INSTANCE_PUBLIC_ACCESS_CHECK"
  }

  depends_on = [aws_config_configuration_recorder_status.this]
}

resource "aws_config_config_rule" "s3_public_read" {
  count = var.enable_aws_config ? 1 : 0

  name = "s3-bucket-public-read-prohibited"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder_status.this]
}

resource "aws_config_config_rule" "kms_rotation" {
  count = var.enable_aws_config ? 1 : 0

  name = "kms-cmk-backing-key-rotation-enabled"
  source {
    owner             = "AWS"
    source_identifier = "CMK_BACKING_KEY_ROTATION_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder_status.this]
}

resource "aws_config_config_rule" "cloudtrail_enabled" {
  count = var.enable_aws_config ? 1 : 0

  name = "cloud-trail-enabled"
  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder_status.this]
}
