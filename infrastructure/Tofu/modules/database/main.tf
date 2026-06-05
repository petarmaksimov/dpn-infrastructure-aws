resource "aws_db_subnet_group" "this" {
  name       = "dbsg-${var.project_name}-${var.environment}"
  subnet_ids = var.private_subnet_ids

  tags = var.tags
}

resource "random_password" "db_admin" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

locals {
  db_admin_secret_name = var.db_admin_secret_name != "" ? var.db_admin_secret_name : "${var.project_name}/${var.environment}/postgres/admin"
}

resource "aws_secretsmanager_secret" "db_admin" {
  name                    = local.db_admin_secret_name
  description             = "Generated PostgreSQL administrator credentials for ${var.project_name}-${var.environment}"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = 7

  tags = merge(var.tags, {
    Name      = local.db_admin_secret_name
    Component = "rds"
    SecretFor = "postgres-admin"
  })
}

resource "aws_db_instance" "this" {
  identifier                 = "rds-${var.project_name}-${var.environment}"
  engine                     = "postgres"
  engine_version             = var.db_engine_version
  instance_class             = var.db_instance_class
  db_name                    = var.db_name
  username                   = var.db_admin_username
  password                   = random_password.db_admin.result
  allocated_storage          = var.db_allocated_storage
  max_allocated_storage      = var.db_max_allocated_storage
  storage_type               = "gp3"
  storage_encrypted          = true
  kms_key_id                 = var.kms_key_arn
  multi_az                   = true
  db_subnet_group_name       = aws_db_subnet_group.this.name
  vpc_security_group_ids     = [var.database_security_group_id]
  backup_retention_period    = var.backup_retention_days
  skip_final_snapshot        = false
  final_snapshot_identifier  = "rds-${var.project_name}-${var.environment}-final"
  deletion_protection        = true
  copy_tags_to_snapshot      = true
  publicly_accessible        = false
  auto_minor_version_upgrade = true
  apply_immediately          = false

  performance_insights_enabled    = true
  performance_insights_kms_key_id = var.kms_key_arn

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "db_admin" {
  secret_id = aws_secretsmanager_secret.db_admin.id

  secret_string = jsonencode({
    username = var.db_admin_username
    password = random_password.db_admin.result
    engine   = "postgres"
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    dbname   = var.db_name
  })
}
