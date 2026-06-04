variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "database_security_group_id" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_engine_version" {
  type = string
}

variable "db_instance_class" {
  type = string
}

variable "db_allocated_storage" {
  type = number
}

variable "db_max_allocated_storage" {
  type = number
}

variable "db_admin_username" {
  type = string
}

variable "db_admin_secret_name" {
  type    = string
  default = ""
}

variable "backup_retention_days" {
  type = number
}

variable "tags" {
  type    = map(string)
  default = {}
}
