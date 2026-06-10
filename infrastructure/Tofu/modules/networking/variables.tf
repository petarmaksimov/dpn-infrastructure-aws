variable "project_name" {
  description = "Project short name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "azs" {
  description = "AZs used by this deployment"
  type        = list(string)
}

variable "subnet_cidrs" {
  description = "Per-tier subnet CIDRs, one per AZ"
  type = object({
    public = list(string)
    app    = list(string)
    data   = list(string)
    fw     = list(string)
    tgw    = list(string)
    mgmt   = list(string)
  })
}

variable "allowed_egress_fqdns" {
  description = "Allowed domains for stateful firewall rules"
  type        = list(string)
  default     = []
}

variable "firewall_flow_log_group_arn" {
  description = "CloudWatch log group ARN for firewall flow logs"
  type        = string
  default     = null
}

variable "vpc_flow_log_group_arn" {
  description = "CloudWatch log group ARN for VPC flow logs"
  type        = string
  default     = null
}

variable "firewall_alert_log_group_arn" {
  description = "CloudWatch log group ARN for firewall alert logs"
  type        = string
  default     = null
}

variable "enable_vpc_endpoints" {
  description = "Enable interface and gateway VPC endpoints for private AWS API access"
  type        = bool
  default     = true
}

variable "enable_restrictive_endpoint_policies" {
  description = "Apply restrictive endpoint policies to gateway and interface endpoints"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}


variable "enable_vpc_flow_logs" {
  description = "Enable VPC flow logging resources. Uses explicit boolean to avoid unknown count during planning."
  type        = bool
  default     = true
}

variable "enable_network_firewall_logging" {
  description = "Enable AWS Network Firewall logging configuration. Uses explicit boolean to avoid unknown count during planning."
  type        = bool
  default     = true
}
