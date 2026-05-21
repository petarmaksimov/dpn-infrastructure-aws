variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "alb_security_group_id" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "ingress_hostname" {
  type = string
}

variable "route53_zone_id" {
  type = string
}

variable "enable_waf" {
  type    = bool
  default = true
}

variable "waf_rate_limit" {
  type    = number
  default = 2000
}

variable "blocked_country_codes" {
  type    = list(string)
  default = []
}

variable "alb_logs_bucket_name" {
  type    = string
  default = null
}

variable "waf_log_group_arn" {
  type    = string
  default = null
}

variable "waf_allowed_http_methods" {
  type    = list(string)
  default = ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"]
}

variable "waf_blocked_user_agent_regexes" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
