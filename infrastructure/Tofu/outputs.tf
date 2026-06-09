output "vpc_id" {
  description = "AWS VPC id"
  value       = module.networking.vpc_id
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS private API endpoint"
  value       = module.eks.cluster_endpoint
}

output "alb_dns_name" {
  description = "Public ALB DNS name"
  value       = module.ingress.alb_dns_name
}

output "waf_web_acl_arn" {
  description = "WAFv2 web ACL ARN"
  value       = module.ingress.waf_web_acl_arn
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = module.database.rds_endpoint
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.container_registry.repository_url
}

output "irsa_role_arns" {
  description = "IRSA role ARNs by role key"
  value       = module.workload_identity.role_arns
}


output "db_admin_secret_arn" {
  description = "Secrets Manager secret ARN for generated RDS PostgreSQL administrator credentials"
  value       = module.database.db_admin_secret_arn
}

output "db_admin_secret_name" {
  description = "Secrets Manager secret name for generated RDS PostgreSQL administrator credentials"
  value       = module.database.db_admin_secret_name
}


output "eks_access_entry_principal_arns" {
  description = "EKS access entry principal ARNs by entry key"
  value       = module.eks.access_entry_principal_arns
}


output "data_bucket_name" {
  description = "Private encrypted DPN data bucket name"
  value       = module.storage.bucket_name
}

output "data_bucket_arn" {
  description = "Private encrypted DPN data bucket ARN"
  value       = module.storage.bucket_arn
}
