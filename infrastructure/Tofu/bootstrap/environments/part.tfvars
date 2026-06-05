# ==============================================================================
# Bootstrap Environment Configuration - PART
# ==============================================================================
# Configuration for the PART environment bootstrap infrastructure.
# These variables are used by the CI/CD pipelines and local deployments.
# ==============================================================================

# AWS Region
aws_region = "eu-west-2"

# Project and environment names
project_name = "dpn"
environment  = "part"

# OpenTofu state storage configuration
tfstate_bucket_name    = "dpn-tfstate-part-001"
tfstate_dynamodb_table = "dpn-tfstate-lock"

# Audit and compliance
enable_cloudtrail_audit      = true
log_retention_days           = 30
enable_mfa_delete            = false
kms_key_deletion_window_days = 7

# Additional tags
tags = {
  Owner      = "Platform-Engineering"
  CostCenter = "Infrastructure"
  Compliance = "SOC2"
  DataClass  = "Internal"
}
