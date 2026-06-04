variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "enable_guardduty" {
  type    = bool
  default = true
}

variable "enable_security_hub" {
  type    = bool
  default = true
}

variable "enable_cloudtrail" {
  type    = bool
  default = true
}

variable "enable_aws_config" {
  type    = bool
  default = true
}

variable "enable_session_manager_preferences" {
  type    = bool
  default = true
}

variable "ssm_sessions_log_group_name" {
  type    = string
  default = null
}

variable "ssm_logs_bucket_name" {
  type    = string
  default = null
}

variable "ssm_idle_session_timeout_minutes" {
  type    = number
  default = 20
}

variable "ssm_max_session_duration_minutes" {
  type    = number
  default = 60
}

variable "ssm_run_as_default_user" {
  type    = string
  default = "ssm-user"
}

variable "tags" {
  type    = map(string)
  default = {}
}
