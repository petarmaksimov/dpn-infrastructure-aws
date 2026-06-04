# Database Module

## Overview

The database module provisions a production-ready RDS PostgreSQL instance with:
- **Multi-AZ Deployment** - Automatic failover for high availability
- **Encryption** - KMS encryption at rest and in transit
- **Automated Backups** - Automated snapshots and point-in-time recovery
- **Performance Insights** - Monitor database performance
- **Secrets Management** - Master password stored in AWS Secrets Manager
- **Deletion Protection** - Prevent accidental deletion

## Key Features

- **Instance Class**: db.m6i.large (2 vCPU, 8GB RAM)
- **Storage**: 100 GB initial, auto-scaling to 500 GB
- **Engine**: PostgreSQL (15.4+)
- **Multi-AZ**: Enabled with automatic failover
- **Encryption**: KMS customer-managed key
- **Backup Retention**: 35 days
- **Deletion Protection**: Enabled
- **Performance Insights**: Enabled

## Resources Created

### RDS PostgreSQL Instance
- **Identifier**: `rds-{project}-{environment}`
- **Multi-AZ**: Automatic failover in < 2 minutes
- **Encryption**: KMS key encryption at rest
- **Secrets Manager**: Master password stored securely
- **Backups**: Automated daily snapshots

### Related Resources
- **DB Subnet Group** - Private subnet placement
- **Security Group** - Ingress rules (port 5432)
- **Parameter Group** - Database configuration
- **Enhanced Monitoring** - CloudWatch metrics

## Key Variables

- `project_name` - Project name (default: "dpn")
- `environment` - Environment name (default: "part")
- `db_name` - Initial database name (default: "appdb")
- `db_instance_class` - Instance type (default: "db.m6i.large")
- `db_allocated_storage` - Initial storage GB (default: 100)
- `db_max_allocated_storage` - Max auto-scaling GB (default: 500)
- `backup_retention_days` - Retention days (default: 35)
- `private_subnet_ids` - Subnets for deployment
- `kms_key_arn` - KMS key for encryption

## Outputs

- `db_instance_id` - Database instance identifier
- `db_instance_endpoint` - Database endpoint (host:port)
- `db_instance_address` - Database hostname
- `db_instance_port` - Database port (5432)
- `db_name` - Database name
- `db_username` - Master username
- `db_password_secret_arn` - Secrets Manager secret ARN

## Usage Examples

### Connect to Database

```bash
# Get password
PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id /rds/dpn-part/master-password \
  --query SecretString --output text)

# Connect
psql -h {db-endpoint} -U postgres -d appdb
```

### Create Snapshot

```bash
aws rds create-db-snapshot \
  --db-instance-identifier rds-dpn-part \
  --db-snapshot-identifier rds-dpn-part-backup-$(date +%s)
```

### Enable IAM Authentication

```bash
export PGPASSWORD="$(aws rds generate-db-auth-token \
  --hostname {db-endpoint} \
  --port 5432 \
  --region eu-west-2 \
  --username iamuser)"
```

## Multi-AZ Failover

**Automatic Failover** (< 2 minutes):
1. Primary failure detected
2. Standby promoted to primary
3. New standby created
4. DNS automatically updated

**Manual Failover** (for testing):
```bash
aws rds reboot-db-instance \
  --db-instance-identifier rds-dpn-part \
  --force-failover
```

## Backup & Recovery

### Automated Backups
- **Retention**: 35 days
- **Frequency**: Nightly
- **Point-in-time recovery**: Any second within retention

### Point-in-Time Recovery

```bash
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier rds-dpn-part \
  --target-db-instance-identifier rds-dpn-part-restored \
  --restore-time 2024-01-15T14:30:00Z
```

## Security Best Practices

✅ **Implemented:**
- Multi-AZ deployment
- KMS encryption at rest
- TLS encryption in transit
- Private subnet placement
- Security group controls
- Deletion protection
- Automated backups (35 days)
- Master password in Secrets Manager

## Cost Optimization

- **Instance**: ~$0.29/hour (db.m6i.large, on-demand)
- **Storage**: $0.12/GB-month (GP3)
- **Backup**: $0.095/GB-month
- **Reserved Instances**: 40-50% discount for 1-3 years

### Optimize Costs
1. Right-size instance (start smaller, scale up)
2. Use Reserved Instances for predictable workloads
3. Adjust backup retention if not needed
4. Monitor storage usage
5. Use single-AZ for dev/test

## Monitoring

### CloudWatch Metrics
- CPUUtilization
- DatabaseConnections
- FreeStorageSpace
- ReadLatency / WriteLatency
- ReplicationLatency (for read replicas)

### View Connections

```bash
psql -h {db-endpoint} -U postgres -d appdb -c \
  "SELECT count(*) FROM pg_stat_activity;"
```

## Troubleshooting

### Cannot Connect
1. Verify security group allows 5432
2. Check instance status
3. Test network connectivity: `telnet {endpoint} 5432`

### High CPU Usage
```sql
SELECT pid, query FROM pg_stat_activity WHERE query NOT LIKE '%pg_stat%';
```

### Disk Space Low
```sql
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) 
FROM pg_tables ORDER BY pg_total_relation_size DESC LIMIT 10;
```

## Dependencies

- **Security Module** - Provides KMS key
- **Networking Module** - Provides subnets and security groups

## References

- [RDS Documentation](https://docs.aws.amazon.com/rds/)
- [PostgreSQL Best Practices on RDS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)
- [Multi-AZ Deployments](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html)
