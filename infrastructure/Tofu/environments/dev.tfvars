# AWS Account ID: 627657103820 (dpn-dev-01)
project_name = "dpn"
environment  = "dev"
aws_region   = "eu-west-2"

cluster_name       = "eks-dpn-dev-eu-west-2"
kubernetes_version = "1.33"

vpc_cidr = "10.85.32.0/24"
azs      = ["eu-west-2a", "eu-west-2b"]

subnet_cidrs = {
  tgw    = ["10.85.32.0/28", "10.85.32.16/28"]
  fw     = ["10.85.32.32/28", "10.85.32.48/28"]
  public = ["10.85.32.64/28", "10.85.32.80/28"]
  mgmt   = ["10.85.32.96/28", "10.85.32.112/28"]
  app    = ["10.85.32.128/26", "10.85.32.192/26"]
  data   = ["10.85.32.224/28", "10.85.32.240/28"]
}

domain_name      = "dpn-dev.example.com"
ingress_hostname = "dpn-dev"
route53_zone_id  = "REPLACE_WITH_DEV_ROUTE53_ZONE_ID"

endpoint_private_access = true
endpoint_public_access  = false

eks_authentication_mode                         = "API_AND_CONFIG_MAP"
eks_bootstrap_cluster_creator_admin_permissions = true

eks_access_entries = {
  admin = {
    principal_arn     = "arn:aws:iam::627657103820:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_EKSAdmin_a8d6203f7d2ec862"
    policy_arn        = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
    access_scope_type = "cluster"
  }

  devops = {
    principal_arn     = "arn:aws:iam::627657103820:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_EKSDevOps_f8e10dc1e40da1f1"
    policy_arn        = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
    access_scope_type = "cluster"
  }
}

system_node_group_instance_types = ["t3.medium"]
system_node_group_desired_size   = 1
system_node_group_min_size       = 1
system_node_group_max_size       = 2

workload_node_group_instance_types = ["t3.large"]
workload_node_group_desired_size   = 1
workload_node_group_min_size       = 1
workload_node_group_max_size       = 3

db_name                  = "dpn"
db_engine_version        = "16.3"
db_instance_class        = "db.t4g.medium"
db_allocated_storage     = 30
db_max_allocated_storage = 100
db_admin_username        = "dpnadmin"
backup_retention_days    = 7

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
  ".compute.amazonaws.com",
  "packages.us-east-1.amazonaws.com"
]

tags = {
  project      = "dpn"
  environment  = "dev"
  managed_by   = "opentofu"
  data_class   = "participant"
  architecture = "dsi-reference-dev"
}

# Example IRSA map. Replace with least-privilege policies per workload.
irsa_service_accounts = {
  external-secrets = {
    namespace       = "external-secrets"
    service_account = "external-secrets-sa"

    policy_json = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:*:*:secret:dpn/dev/*"
    }
  ]
}
POLICY
  }
}

# Baseline AWS Config Rules (for gradual compliance enablement)
# These are example AWS managed rules in audit (non-enforcing) mode. Expand as needed.
aws_config_baseline = {
  "restricted-ssh" = {
    description      = "Checks whether security groups allow unrestricted SSH access."
    rule_identifier  = "INCOMING_SSH_DISABLED"
    input_parameters = {}
    compliance_mode  = "Audit"
  }
  "s3-bucket-public-read-prohibited" = {
    description      = "Checks that S3 buckets do not allow public read access."
    rule_identifier  = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
    input_parameters = {}
    compliance_mode  = "Audit"
  }
  "rds-storage-encrypted" = {
    description      = "Checks whether storage encryption is enabled for your RDS DB instances."
    rule_identifier  = "RDS_STORAGE_ENCRYPTED"
    input_parameters = {}
    compliance_mode  = "Audit"
  }
}

db_admin_secret_name = "dpn/dev/postgres/admin"

data_bucket_name                               = "dpn-dev-627657103820-eu-west-2-data"
data_bucket_force_destroy                      = false
data_bucket_noncurrent_version_expiration_days = 90