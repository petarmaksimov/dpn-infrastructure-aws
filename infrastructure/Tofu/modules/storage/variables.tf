variable "bucket_name" {
  description = "Name of the private encrypted S3 bucket."
  type        = string
}

variable "force_destroy" {
  description = "Allow bucket deletion even if objects exist."
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS key ARN used for bucket encryption."
  type        = string
}

variable "noncurrent_version_expiration_days" {
  description = "Number of days before noncurrent object versions expire."
  type        = number
  default     = 90
}

variable "tags" {
  description = "Tags applied to the bucket resources."
  type        = map(string)
  default     = {}
}
