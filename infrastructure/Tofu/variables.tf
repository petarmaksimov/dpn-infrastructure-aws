# ========================================
# Core Variables
# ========================================

variable "project_name" {
  description = "Project short name used in naming conventions"
  type        = string
}

variable "environment" {
  description = "Environment name (for example: prod, test, dev)"
  type        = string
}

variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "eu-west-2"
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}

# ========================================
# Networking Variables
# ========================================

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "azs" {
  description = "Availability zones used by this deployment"
  type        = list(string)
}

variable "subnet_cidrs" {
  description = "CIDR blocks for each subnet tier, one CIDR per AZ"
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
  description = "FQDN allow-list for AWS Network Firewall stateful egress policy"
  type        = list(string)
  default = [
    ".amazonaws.com",
    ".ecr.amazonaws.com",
    ".ecr.aws",
    ".eks.amazonaws.com",
    ".compute.amazonaws.com",
    "packages.us-east-1.amazonaws.com"
  ]
}

# ========================================
# EKS Variables
# ========================================

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "Minimum Kubernetes version per baseline is 1.33"
  type        = string
  default     = "1.33"
}

variable "endpoint_private_access" {
  description = "Enable private endpoint access for EKS API"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public endpoint access for EKS API"
  type        = bool
  default     = false
}

variable "endpoint_public_access_cidrs" {
  description = "CIDRs allowed to access public EKS endpoint when enabled"
  type        = list(string)
  default     = []
}

variable "cluster_log_types" {
  description = "EKS control plane log types"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "eks_authentication_mode" {
  description = "EKS authentication mode. API_AND_CONFIG_MAP allows EKS Access Entries while preserving aws-auth compatibility."
  type        = string
  default     = "API_AND_CONFIG_MAP"
}

variable "eks_bootstrap_cluster_creator_admin_permissions" {
  description = "Grant temporary cluster admin permissions to the principal creating the EKS cluster."
  type        = bool
  default     = true
}

variable "eks_access_entries" {
  description = "EKS access entries for human IAM/SSO principals."
  type = map(object({
    principal_arn     = string
    policy_arn        = string
    access_scope_type = string
  }))
  default = {}
}

variable "system_node_group_name" {
  description = "System node group name"
  type        = string
  default     = "system"
}

variable "system_node_group_instance_types" {
  description = "System node group instance types"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "system_node_group_desired_size" {
  description = "Desired node count for system node group"
  type        = number
  default     = 3
}

variable "system_node_group_min_size" {
  description = "Minimum node count for system node group"
  type        = number
  default     = 3
}

variable "system_node_group_max_size" {
  description = "Maximum node count for system node group"
  type        = number
  default     = 3
}

variable "workload_node_group_name" {
  description = "Workload node group name"
  type        = string
  default     = "workload"
}

variable "workload_node_group_instance_types" {
  description = "Workload node group instance types"
  type        = list(string)
  default     = ["t3.xlarge"]
}

variable "workload_node_group_desired_size" {
  description = "Desired node count for workload node group"
  type        = number
  default     = 3
}

variable "workload_node_group_min_size" {
  description = "Minimum node count for workload node group"
  type        = number
  default     = 3
}

variable "workload_node_group_max_size" {
  description = "Maximum node count for workload node group"
  type        = number
  default     = 12
}

# ========================================
# Ingress and WAF
# ========================================

variable "domain_name" {
  description = "FQDN used by ACM certificate and ingress endpoint"
  type        = string
}

variable "ingress_hostname" {
  description = "DNS record name created in Route53 for ALB alias"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 public hosted zone id for certificate validation and ALB alias"
  type        = string
}

variable "enable_waf" {
  description = "Enable WAFv2 web ACL association on ALB"
  type        = bool
  default     = true
}

variable "waf_rate_limit" {
  description = "Rate based WAF rule limit per 5-minute period"
  type        = number
  default     = 2000
}

variable "blocked_country_codes" {
  description = "ISO country codes blocked by WAF geo restriction rule"
  type        = list(string)
  default     = []
}

variable "waf_allowed_http_methods" {
  description = "HTTP methods allowed by custom WAF rule"
  type        = list(string)
  default     = ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"]
}

variable "waf_blocked_user_agent_regexes" {
  description = "Regex patterns for malicious user agents blocked by WAF custom rule"
  type        = list(string)
  default = [
    "(?i).*sqlmap.*",
    "(?i).*nikto.*",
    "(?i).*nmap.*",
    "(?i).*masscan.*",
    "(?i).*acunetix.*",
    "(?i).*dirbuster.*",
    "(?i).*zaproxy.*"
  ]
}

# ========================================
# Database Variables
# ========================================

variable "db_name" {
  description = "RDS PostgreSQL database name"
  type        = string
  default     = "dpn"
}

variable "db_engine_version" {
  description = "RDS PostgreSQL engine version"
  type        = string
  default     = "16.3"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.m6i.large"
}

variable "db_allocated_storage" {
  description = "Initial RDS storage in GiB"
  type        = number
  default     = 100
}

variable "db_max_allocated_storage" {
  description = "Maximum autoscaled RDS storage in GiB"
  type        = number
  default     = 500
}

variable "db_admin_username" {
  description = "Master username for RDS"
  type        = string
  default     = "dpnadmin"
}

variable "db_admin_secret_name" {
  description = "AWS Secrets Manager secret name for the generated RDS PostgreSQL administrator credentials"
  type        = string
  default     = ""
}

variable "backup_retention_days" {
  description = "RDS backup retention in days"
  type        = number
  default     = 35
}

# ========================================
# Storage Variables
# ========================================

variable "data_bucket_name" {
  description = "Private encrypted S3 bucket for DPN participant/application data. No workload access is granted by default."
  type        = string
}

variable "data_bucket_force_destroy" {
  description = "Allow force destroy of the data bucket. Keep false for normal environments."
  type        = bool
  default     = false
}

variable "data_bucket_noncurrent_version_expiration_days" {
  description = "Number of days before noncurrent object versions expire."
  type        = number
  default     = 90
}

# ========================================
# ECR and Logging Variables
# ========================================

variable "ecr_image_tag_mutability" {
  description = "ECR image tag mutability setting"
  type        = string
  default     = "IMMUTABLE"
}

variable "ecr_scan_on_push" {
  description = "Enable ECR vulnerability scanning on push"
  type        = bool
  default     = true
}

variable "log_retention_in_days" {
  description = "CloudWatch log group retention"
  type        = number
  default     = 90
}

variable "create_log_s3_buckets" {
  description = "Create S3 buckets for ALB, firewall, and SSM logs"
  type        = bool
  default     = true
}

variable "enable_vpc_endpoints" {
  description = "Enable VPC endpoints for private AWS API access"
  type        = bool
  default     = true
}

variable "enable_restrictive_endpoint_policies" {
  description = "Apply restrictive endpoint policies (action-scoped allow lists)"
  type        = bool
  default     = true
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC flow logging resources"
  type        = bool
  default     = true
}

variable "enable_network_firewall_logging" {
  description = "Enable AWS Network Firewall logging configuration"
  type        = bool
  default     = true
}

variable "enable_waf_logging" {
  description = "Enable WAF logging configuration"
  type        = bool
  default     = true
}


variable "enable_guardduty" {
  description = "Enable Amazon GuardDuty detector"
  type        = bool
  default     = true
}

variable "enable_security_hub" {
  description = "Enable AWS Security Hub for the account"
  type        = bool
  default     = true
}

variable "enable_cloudtrail" {
  description = "Enable CloudTrail with encrypted S3 log delivery"
  type        = bool
  default     = true
}

variable "enable_aws_config" {
  description = "Enable AWS Config recorder and baseline managed config rules"
  type        = bool
  default     = true
}

variable "enable_session_manager_preferences" {
  description = "Create Session Manager preference document as IaC"
  type        = bool
  default     = true
}

variable "ssm_idle_session_timeout_minutes" {
  description = "Session Manager idle timeout in minutes"
  type        = number
  default     = 20
}

variable "ssm_max_session_duration_minutes" {
  description = "Session Manager maximum session duration in minutes"
  type        = number
  default     = 60
}

variable "ssm_run_as_default_user" {
  description = "Default OS user for Session Manager run-as mode"
  type        = string
  default     = "ssm-user"
}

# ========================================
# IRSA Variables
# ========================================

variable "irsa_service_accounts" {
  description = "IRSA role map keyed by role short name"
  type = map(object({
    namespace       = string
    service_account = string
    policy_json     = string
  }))
  default = {}
}
