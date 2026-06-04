output "rds_endpoint" {
  value = aws_db_instance.this.address
}

output "rds_port" {
  value = aws_db_instance.this.port
}

output "db_admin_secret_arn" {
  value       = aws_secretsmanager_secret.db_admin.arn
  description = "ARN of the Secrets Manager secret containing generated PostgreSQL admin credentials"
}


output "db_admin_secret_name" {
  value       = aws_secretsmanager_secret.db_admin.name
  description = "Name of the Secrets Manager secret containing generated PostgreSQL admin credentials"
}
