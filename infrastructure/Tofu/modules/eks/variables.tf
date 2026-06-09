variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "node_security_group_id" {
  type = string
}

variable "cluster_role_arn" {
  type = string
}

variable "node_role_arn" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "endpoint_private_access" {
  type    = bool
  default = true
}

variable "endpoint_public_access" {
  type    = bool
  default = false
}

variable "endpoint_public_access_cidrs" {
  type    = list(string)
  default = []
}

variable "cluster_log_types" {
  type    = list(string)
  default = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "system_node_group" {
  type = object({
    name           = string
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
  })
}

variable "workload_node_group" {
  type = object({
    name           = string
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
  })
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "authentication_mode" {
  type    = string
  default = "API_AND_CONFIG_MAP"
}
variable "bootstrap_cluster_creator_admin_permissions" {
  type    = bool
  default = true
}
variable "access_entries" {
  type = map(object({
    principal_arn     = string
    policy_arn        = string
    access_scope_type = string
  }))
  default = {}
}
