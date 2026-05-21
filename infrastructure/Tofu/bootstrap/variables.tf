# ==============================================================================
# Bootstrap Infrastructure Variables
# ==============================================================================

variable "aws_region" {
  description = "AWS region for bootstrap resources"
  type        = string
  default     = "eu-west-2"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "AWS region must be a valid region identifier (e.g., eu-west-2)."
  }
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "dpn"

  validation {
    condition     = can(regex("^[a-z0-9]{1,8}$", var.project_name))
    error_message = "Project name must be 1-8 lowercase alphanumeric characters."
  }
}

variable "environment" {
  description = "Environment name (e.g., part, prod, dev)"
  type        = string
  default     = "part"

  validation {
    condition     = can(regex("^[a-z0-9]{1,10}$", var.environment))
    error_message = "Environment must be 1-10 lowercase alphanumeric characters."
  }
}

variable "tfstate_bucket_name" {
  description = "S3 bucket name for storing OpenTofu state files"
  type        = string
  default     = ""

  validation {
    condition     = var.tfstate_bucket_name == "" || can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.tfstate_bucket_name))
    error_message = "S3 bucket name must follow AWS naming rules (3-63 chars, lowercase, hyphens allowed)."
  }
}

variable "tfstate_dynamodb_table" {
  description = "DynamoDB table name for state locking"
  type        = string
  default     = ""

  validation {
    condition     = var.tfstate_dynamodb_table == "" || can(regex("^[a-zA-Z0-9_-]{1,255}$", var.tfstate_dynamodb_table))
    error_message = "DynamoDB table name must be 1-255 characters with alphanumeric, underscore, and hyphen characters."
  }
}

variable "enable_cloudtrail_audit" {
  description = "Enable CloudTrail audit logging for state access"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention must be a valid CloudWatch retention period."
  }
}

variable "enable_mfa_delete" {
  description = "Enable MFA delete on S3 state bucket (requires MFA device)"
  type        = bool
  default     = false
}

variable "kms_key_deletion_window_days" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 7

  validation {
    condition     = var.kms_key_deletion_window_days >= 7 && var.kms_key_deletion_window_days <= 30
    error_message = "KMS key deletion window must be between 7 and 30 days."
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
