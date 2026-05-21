variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "log_retention_in_days" {
  type = number
}

variable "kms_key_arn" {
  type    = string
  default = null
}

variable "create_log_s3_buckets" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
