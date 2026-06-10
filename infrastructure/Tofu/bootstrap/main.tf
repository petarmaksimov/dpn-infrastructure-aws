# ==============================================================================
# OpenTofu Bootstrap Infrastructure
# ==============================================================================
# Creates the foundational infrastructure required for OpenTofu state management:
#   - S3 bucket for storing OpenTofu state files
#   - DynamoDB table for state locking (prevents concurrent modifications)
#   - KMS key for encrypting state files
#   - IAM policies for state access (optional, managed via service principals)
#
# This bootstrap configuration uses local state during initial setup.
# Once AWS resources are created, state can be migrated to S3 backend.
# ==============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "OpenTofu"
      Bootstrap   = "true"
    }
  }
}

data "aws_caller_identity" "current" {}

# ==============================================================================
# KMS Key for S3 Encryption
# ==============================================================================
resource "aws_kms_key" "tfstate" {
  description             = "KMS key for encrypting ${var.project_name} OpenTofu state"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.project_name}-tfstate-key"
  }
}

resource "aws_kms_alias" "tfstate" {
  name          = "alias/${var.project_name}-tfstate"
  target_key_id = aws_kms_key.tfstate.key_id
}

# ==============================================================================
# S3 Bucket for OpenTofu State
# ==============================================================================
resource "aws_s3_bucket" "tfstate" {
  bucket = var.tfstate_bucket_name

  tags = {
    Name = var.tfstate_bucket_name
  }
}

# Enable versioning on S3 bucket
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status     = "Enabled"
    mfa_delete = "Disabled" # Set to "Enabled" in production with MFA
  }
}

# Enable server-side encryption with KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.tfstate.arn
    }
    bucket_key_enabled = true
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable logging
resource "aws_s3_bucket_logging" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  target_bucket = aws_s3_bucket.tfstate_logs.id
  target_prefix = "tfstate-access-logs/"
}

# Enable bucket policy to deny unencrypted uploads
resource "aws_s3_bucket_policy" "tfstate_enforce_encryption" {
  bucket = aws_s3_bucket.tfstate.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyUnencryptedObjectUploads"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.tfstate.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      },
      {
        Sid       = "DenyIncorrectKmsKey"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.tfstate.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption-aws-kms-key-id" = aws_kms_key.tfstate.arn
          }
        }
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.tfstate.arn,
          "${aws_s3_bucket.tfstate.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# ==============================================================================
# S3 Bucket for Access Logs
# ==============================================================================
resource "aws_s3_bucket" "tfstate_logs" {
  bucket = "${var.tfstate_bucket_name}-logs"

  tags = {
    Name = "${var.tfstate_bucket_name}-logs"
  }
}

resource "aws_s3_bucket_versioning" "tfstate_logs" {
  bucket = aws_s3_bucket.tfstate_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate_logs" {
  bucket = aws_s3_bucket.tfstate_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate_logs" {
  bucket = aws_s3_bucket.tfstate_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle policy to delete logs after 90 days
resource "aws_s3_bucket_lifecycle_configuration" "tfstate_logs" {
  bucket = aws_s3_bucket.tfstate_logs.id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# ==============================================================================
# DynamoDB Table for State Locking
# ==============================================================================
resource "aws_dynamodb_table" "tfstate_lock" {
  name             = var.tfstate_dynamodb_table
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "LockID"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.tfstate.arn
  }

  ttl {
    attribute_name = "ExpirationTime"
    enabled        = true
  }

  tags = {
    Name = var.tfstate_dynamodb_table
  }
}

# ==============================================================================
# CloudWatch Log Group for Monitoring (Optional)
# ==============================================================================
resource "aws_cloudwatch_log_group" "tfstate_audit" {
  name              = "/aws/tfstate/${var.environment}/audit"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-tfstate-audit"
  }
}

# ==============================================================================
# CloudTrail for Audit Logging (Optional)
# ==============================================================================
resource "aws_cloudtrail" "tfstate" {
  count                         = var.enable_cloudtrail_audit ? 1 : 0
  name                          = "${var.project_name}-tfstate-trail"
  s3_bucket_name                = aws_s3_bucket.tfstate_audit[0].id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  depends_on                    = [aws_s3_bucket_policy.tfstate_audit[0]]

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.tfstate.arn}/*"]
    }

    data_resource {
      type = "AWS::DynamoDB::Table"
      values = [
        "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.tfstate_dynamodb_table}"
      ]
    }
  }
}

resource "aws_s3_bucket" "tfstate_audit" {
  count  = var.enable_cloudtrail_audit ? 1 : 0
  bucket = "${var.tfstate_bucket_name}-audit"

  tags = {
    Name = "${var.tfstate_bucket_name}-audit"
  }
}

resource "aws_s3_bucket_versioning" "tfstate_audit" {
  count  = var.enable_cloudtrail_audit ? 1 : 0
  bucket = aws_s3_bucket.tfstate_audit[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate_audit" {
  count  = var.enable_cloudtrail_audit ? 1 : 0
  bucket = aws_s3_bucket.tfstate_audit[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "tfstate_audit" {
  count  = var.enable_cloudtrail_audit ? 1 : 0
  bucket = aws_s3_bucket.tfstate_audit[0].id

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
        Resource = aws_s3_bucket.tfstate_audit[0].arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.tfstate_audit[0].arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}