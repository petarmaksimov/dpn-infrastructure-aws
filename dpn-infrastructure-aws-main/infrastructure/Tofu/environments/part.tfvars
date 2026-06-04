project_name = "dpn"
environment  = "prod"
aws_region   = "eu-west-2"

cluster_name       = "eks-dpn-prod-eu-west-2"
kubernetes_version = "1.33"

vpc_cidr = "10.120.0.0/16"
azs      = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]

subnet_cidrs = {
  public = ["10.120.0.0/24", "10.120.1.0/24", "10.120.2.0/24"]
  app    = ["10.120.10.0/24", "10.120.11.0/24", "10.120.12.0/24"]
  data   = ["10.120.20.0/24", "10.120.21.0/24", "10.120.22.0/24"]
  fw     = ["10.120.30.0/28", "10.120.30.16/28", "10.120.30.32/28"]
  tgw    = ["10.120.40.0/28", "10.120.40.16/28", "10.120.40.32/28"]
  mgmt   = ["10.120.50.0/24", "10.120.51.0/24", "10.120.52.0/24"]
}

domain_name      = "dpn.example.com"
ingress_hostname = "dpn"
route53_zone_id  = "Z000000000EXAMPLE"

endpoint_private_access = true
endpoint_public_access  = false

system_node_group_instance_types = ["t3.medium"]
system_node_group_desired_size   = 3
system_node_group_min_size       = 3
system_node_group_max_size       = 3

workload_node_group_instance_types = ["t3.xlarge"]
workload_node_group_desired_size   = 3
workload_node_group_min_size       = 3
workload_node_group_max_size       = 12

db_name                  = "dpn"
db_engine_version        = "16.3"
db_instance_class        = "db.m6i.large"
db_allocated_storage     = 100
db_max_allocated_storage = 500
db_admin_username        = "dpnadmin"
backup_retention_days    = 35

enable_waf     = true
waf_rate_limit = 2000
blocked_country_codes = [
  "KP",
  "IR",
  "SY"
]
waf_allowed_http_methods = ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"]
waf_blocked_user_agent_regexes = [
  "(?i).*sqlmap.*",
  "(?i).*nikto.*",
  "(?i).*nmap.*",
  "(?i).*masscan.*",
  "(?i).*acunetix.*",
  "(?i).*dirbuster.*",
  "(?i).*zaproxy.*"
]

enable_guardduty                     = true
enable_security_hub                  = true
enable_cloudtrail                    = true
enable_aws_config                    = true
enable_session_manager_preferences   = true
enable_vpc_endpoints                 = true
enable_restrictive_endpoint_policies = true

allowed_egress_fqdns = [
  ".amazonaws.com",
  ".ecr.amazonaws.com",
  ".ecr.aws",
  ".eks.amazonaws.com",
  "packages.us-east-1.amazonaws.com"
]

tags = {
  project      = "dpn"
  environment  = "prod"
  managed_by   = "opentofu"
  data_class   = "participant"
  architecture = "dsi-reference"
}

# Example IRSA map. Replace with least-privilege policies per workload.
irsa_service_accounts = {
  external-secrets = {
    namespace       = "external-secrets"
    service_account = "external-secrets-sa"
    policy_json = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["secretsmanager:GetSecretValue"]
          Resource = "arn:aws:secretsmanager:*:*:secret:dpn/prod/*"
        }
      ]
    })
  }
}

# Baseline AWS Config Rules (for gradual compliance enablement)
# These are example AWS managed rules in audit (non-enforcing) mode. Expand as needed.
aws_config_baseline = {
  "restricted-ssh" = {
    description = "Checks whether security groups allow unrestricted SSH access."
    rule_identifier = "INCOMING_SSH_DISABLED"
    input_parameters = {}
    compliance_mode = "Audit"
  }
  "s3-bucket-public-read-prohibited" = {
    description = "Checks that S3 buckets do not allow public read access."
    rule_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
    input_parameters = {}
    compliance_mode = "Audit"
  }
  "rds-storage-encrypted" = {
    description = "Checks whether storage encryption is enabled for your RDS DB instances."
    rule_identifier = "RDS_STORAGE_ENCRYPTED"
    input_parameters = {}
    compliance_mode = "Audit"
  }
}
