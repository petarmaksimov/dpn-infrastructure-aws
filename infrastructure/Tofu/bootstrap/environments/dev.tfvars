aws_region = "eu-west-2"

project_name = "dpn"
environment  = "dev"

tfstate_bucket_name    = "dpn-tfstate-dev-001"
tfstate_dynamodb_table = "dpn-tfstate-lock-dev"

enable_cloudtrail_audit      = true
log_retention_days           = 30
enable_mfa_delete            = false
kms_key_deletion_window_days = 7

tags = {
  Owner       = "Platform-Engineering"
  CostCenter  = "Infrastructure"
  Compliance  = "DEV"
  DataClass   = "Internal-Dev"
}
