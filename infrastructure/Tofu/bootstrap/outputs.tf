# ==============================================================================
# Bootstrap Infrastructure Outputs
# ==============================================================================

output "tfstate_bucket_name" {
  description = "S3 bucket name for OpenTofu state storage"
  value       = aws_s3_bucket.tfstate.id
}

output "tfstate_bucket_arn" {
  description = "ARN of the S3 bucket for OpenTofu state"
  value       = aws_s3_bucket.tfstate.arn
}

output "tfstate_bucket_region" {
  description = "Region of the S3 bucket for OpenTofu state"
  value       = aws_s3_bucket.tfstate.region
}

output "tfstate_dynamodb_table_name" {
  description = "DynamoDB table name for state locking"
  value       = aws_dynamodb_table.tfstate_lock.name
}

output "tfstate_dynamodb_table_arn" {
  description = "ARN of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.tfstate_lock.arn
}

output "tfstate_kms_key_id" {
  description = "KMS key ID for S3 state encryption"
  value       = aws_kms_key.tfstate.id
  sensitive   = true
}

output "tfstate_kms_key_arn" {
  description = "KMS key ARN for S3 state encryption"
  value       = aws_kms_key.tfstate.arn
  sensitive   = true
}

output "tfstate_kms_key_alias" {
  description = "KMS key alias for S3 state encryption"
  value       = aws_kms_alias.tfstate.name
}

output "backend_config" {
  description = "Backend configuration block to add to main infrastructure"
  value = {
    bucket         = aws_s3_bucket.tfstate.id
    key            = "dev/terraform.tfstate"
    region         = aws_s3_bucket.tfstate.region
    dynamodb_table = aws_dynamodb_table.tfstate_lock.name
    encrypt        = true
    kms_key_id     = aws_kms_key.tfstate.id
  }
}

output "backend_config_hcl" {
  description = "HCL snippet for backend configuration in main infrastructure"
  value       = <<-EOT
    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.tfstate.id}"
        key            = "dev/terraform.tfstate"
        region         = "${aws_s3_bucket.tfstate.region}"
        dynamodb_table = "${aws_dynamodb_table.tfstate_lock.name}"
        encrypt        = true
        kms_key_id     = "${aws_kms_key.tfstate.id}"
      }
    }
  EOT
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group for state audit logs"
  value       = aws_cloudwatch_log_group.tfstate_audit.name
}

output "audit_bucket_name" {
  description = "S3 bucket name for CloudTrail audit logs (if enabled)"
  value       = try(aws_s3_bucket.tfstate_audit[0].id, null)
}

output "deployment_summary" {
  description = "Summary of deployed bootstrap resources"
  value = {
    state_storage = {
      bucket     = aws_s3_bucket.tfstate.id
      encryption = "AWS KMS (${aws_kms_alias.tfstate.name})"
      versioning = "Enabled"
      logging    = "Enabled"
    }
    state_locking = {
      table                  = aws_dynamodb_table.tfstate_lock.name
      billing_mode           = "On-Demand"
      point_in_time_recovery = "Enabled"
      encryption             = "AWS KMS"
    }
    audit = {
      cloudwatch_log_group = aws_cloudwatch_log_group.tfstate_audit.name
      cloudtrail_enabled   = var.enable_cloudtrail_audit
      audit_bucket         = try(aws_s3_bucket.tfstate_audit[0].id, "N/A")
    }
  }
}
