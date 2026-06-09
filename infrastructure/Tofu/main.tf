# ==============================================================================
# DPN AWS EKS Production Infrastructure
# ==============================================================================
# This stack deploys a production-grade AWS baseline that mirrors the
# Azure folder/module pattern in this repository.
#
# Highlights:
# - Multi-AZ VPC with tiered subnets (public, app, data, fw, tgw, mgmt)
# - Egress control path: App -> TGW -> Network Firewall -> NAT -> IGW
# - EKS private endpoint cluster with managed node groups
# - WAF + ALB ingress baseline
# - KMS, ECR, RDS, S3 log sinks, CloudWatch log groups, IRSA roles
# ==============================================================================

module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  tags         = var.tags
}

module "observability" {
  source = "./modules/observability"

  project_name          = var.project_name
  environment           = var.environment
  log_retention_in_days = var.log_retention_in_days
  kms_key_arn           = module.security.kms_key_arn
  create_log_s3_buckets = var.create_log_s3_buckets
  tags                  = var.tags
}

module "networking" {
  source = "./modules/networking"

  project_name                         = var.project_name
  environment                          = var.environment
  aws_region                           = var.aws_region
  vpc_cidr                             = var.vpc_cidr
  azs                                  = var.azs
  subnet_cidrs                         = var.subnet_cidrs
  allowed_egress_fqdns                 = var.allowed_egress_fqdns
  enable_vpc_endpoints                 = var.enable_vpc_endpoints
  enable_restrictive_endpoint_policies = var.enable_restrictive_endpoint_policies
  vpc_flow_log_group_arn               = module.observability.vpc_flow_log_group_arn
  firewall_flow_log_group_arn          = module.observability.firewall_flow_log_group_arn
  firewall_alert_log_group_arn         = module.observability.firewall_alert_log_group_arn
  tags                                 = var.tags
}

module "container_registry" {
  source = "./modules/container_registry"

  project_name         = var.project_name
  environment          = var.environment
  kms_key_arn          = module.security.kms_key_arn
  image_tag_mutability = var.ecr_image_tag_mutability
  scan_on_push         = var.ecr_scan_on_push
  tags                 = var.tags
}

module "storage" {
  source = "./modules/storage"

  bucket_name                        = var.data_bucket_name
  force_destroy                      = var.data_bucket_force_destroy
  kms_key_arn                        = module.security.kms_key_arn
  noncurrent_version_expiration_days = var.data_bucket_noncurrent_version_expiration_days
  tags                               = var.tags
}

module "eks" {
  source = "./modules/eks"

  project_name                                = var.project_name
  environment                                 = var.environment
  cluster_name                                = var.cluster_name
  kubernetes_version                          = var.kubernetes_version
  private_subnet_ids                          = module.networking.application_subnet_ids
  node_security_group_id                      = module.networking.node_security_group_id
  cluster_role_arn                            = module.security.eks_cluster_role_arn
  node_role_arn                               = module.security.eks_node_role_arn
  kms_key_arn                                 = module.security.kms_key_arn
  endpoint_private_access                     = var.endpoint_private_access
  endpoint_public_access                      = var.endpoint_public_access
  endpoint_public_access_cidrs                = var.endpoint_public_access_cidrs
  cluster_log_types                           = var.cluster_log_types
  authentication_mode                         = var.eks_authentication_mode
  bootstrap_cluster_creator_admin_permissions = var.eks_bootstrap_cluster_creator_admin_permissions
  access_entries                              = var.eks_access_entries

  system_node_group = {
    name           = var.system_node_group_name
    instance_types = var.system_node_group_instance_types
    desired_size   = var.system_node_group_desired_size
    min_size       = var.system_node_group_min_size
    max_size       = var.system_node_group_max_size
  }

  workload_node_group = {
    name           = var.workload_node_group_name
    instance_types = var.workload_node_group_instance_types
    desired_size   = var.workload_node_group_desired_size
    min_size       = var.workload_node_group_min_size
    max_size       = var.workload_node_group_max_size
  }

  depends_on = [module.networking, module.security]
}

module "ingress" {
  source = "./modules/ingress"

  project_name                   = var.project_name
  environment                    = var.environment
  vpc_id                         = module.networking.vpc_id
  public_subnet_ids              = module.networking.public_subnet_ids
  alb_security_group_id          = module.networking.alb_security_group_id
  domain_name                    = var.domain_name
  ingress_hostname               = var.ingress_hostname
  route53_zone_id                = var.route53_zone_id
  enable_waf                     = var.enable_waf
  waf_rate_limit                 = var.waf_rate_limit
  blocked_country_codes          = var.blocked_country_codes
  waf_allowed_http_methods       = var.waf_allowed_http_methods
  waf_blocked_user_agent_regexes = var.waf_blocked_user_agent_regexes
  alb_logs_bucket_name           = module.observability.alb_logs_bucket_name
  waf_log_group_arn              = module.observability.waf_log_group_arn
  tags                           = var.tags
}

module "compliance" {
  source = "./modules/compliance"

  project_name                       = var.project_name
  environment                        = var.environment
  aws_region                         = var.aws_region
  kms_key_arn                        = module.security.kms_key_arn
  enable_guardduty                   = var.enable_guardduty
  enable_security_hub                = var.enable_security_hub
  enable_cloudtrail                  = var.enable_cloudtrail
  enable_aws_config                  = var.enable_aws_config
  enable_session_manager_preferences = var.enable_session_manager_preferences
  ssm_sessions_log_group_name        = module.observability.ssm_sessions_log_group_name
  ssm_logs_bucket_name               = module.observability.ssm_logs_bucket_name
  ssm_idle_session_timeout_minutes   = var.ssm_idle_session_timeout_minutes
  ssm_max_session_duration_minutes   = var.ssm_max_session_duration_minutes
  ssm_run_as_default_user            = var.ssm_run_as_default_user
  tags                               = var.tags
}

module "database" {
  source = "./modules/database"

  project_name               = var.project_name
  environment                = var.environment
  private_subnet_ids         = module.networking.data_subnet_ids
  database_security_group_id = module.networking.data_security_group_id
  kms_key_arn                = module.security.kms_key_arn
  db_name                    = var.db_name
  db_engine_version          = var.db_engine_version
  db_instance_class          = var.db_instance_class
  db_allocated_storage       = var.db_allocated_storage
  db_max_allocated_storage   = var.db_max_allocated_storage
  db_admin_username          = var.db_admin_username
  db_admin_secret_name       = var.db_admin_secret_name
  backup_retention_days      = var.backup_retention_days
  tags                       = var.tags
}

module "workload_identity" {
  source = "./modules/workload_identity"

  project_name      = var.project_name
  environment       = var.environment
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_issuer_url   = module.eks.oidc_issuer_url
  service_accounts  = var.irsa_service_accounts

  depends_on = [module.eks]
}
