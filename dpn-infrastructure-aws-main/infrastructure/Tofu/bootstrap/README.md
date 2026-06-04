# Bootstrap Infrastructure

## Overview

This module creates the foundational AWS infrastructure required for OpenTofu state management:

- **S3 Bucket** - Stores OpenTofu state files with encryption, versioning, and access logging
- **DynamoDB Table** - Enables state locking to prevent concurrent modifications
- **KMS Key** - Encrypts state files for enhanced security
- **CloudTrail** - Audits all access to state files and resources
- **CloudWatch Logs** - Monitors state access and changes

## Architecture

```
┌─────────────────────────────────────────────────┐
│           OpenTofu Bootstrap                    │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │ S3 Bucket (tfstate-part-001)            │   │
│  │ - Versioning: Enabled                   │   │
│  │ - Encryption: AWS KMS                   │   │
│  │ - Public Access: Blocked                │   │
│  │ - Logging: S3 bucket logs               │   │
│  │ - Bucket Policy: Enforce encryption     │   │
│  └─────────────────────────────────────────┘   │
│                    ↑                            │
│  ┌─────────────────┼─────────────────────────┐ │
│  │ KMS Key         │                         │ │
│  │ (alias/dpn...)  │                         │ │
│  │ - Rotation: On  │                         │ │
│  │ - Key Policy    │                         │ │
│  └─────────────────┼─────────────────────────┘ │
│                    │                            │
│  ┌─────────────────┼─────────────────────────┐ │
│  │ DynamoDB Table  │                         │ │
│  │ (tfstate-lock)  │                         │ │
│  │ - Encryption: AWS KMS                    │ │
│  │ - PITR: Enabled                          │ │
│  │ - Stream: NEW_AND_OLD_IMAGES              │ │
│  │ - Billing: On-Demand                     │ │
│  └─────────────────────────────────────────┘ │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │ CloudTrail & Audit                      │   │
│  │ - Data Events: S3 & DynamoDB             │   │
│  │ - CloudWatch Logs: 30-day retention     │   │
│  │ - S3 Audit Bucket: Encrypted logs       │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
└─────────────────────────────────────────────────┘
```

## Files

- **main.tf** - Resource definitions (S3, DynamoDB, KMS, CloudTrail)
- **variables.tf** - Input variables with validation
- **outputs.tf** - Exported values for main infrastructure
- **backend-bootstrap.tf** - Backend configuration (local state by default)
- **environments/part.tfvars** - Configuration for PART environment

## State Management

### Initial Deployment (Local State)

During the initial bootstrap, state is stored locally in `bootstrap.tfstate`:

```bash
cd infrastructure/Tofu/bootstrap
tofu init
tofu plan -var-file=environments/part.tfvars
tofu apply -var-file=environments/part.tfvars
```

This is necessary because the S3 bucket doesn't exist yet (chicken-and-egg problem).

### After Initial Deployment (Optional: Migrate to S3)

Once the S3 bucket and DynamoDB table are created, you can optionally migrate bootstrap state to S3:

1. **Uncomment the S3 backend block** in `backend-bootstrap.tf`
2. **Run terraform init** to migrate:
   ```bash
   cd infrastructure/Tofu/bootstrap
   tofu init  # Select "yes" to migrate state
   ```
3. **Verify migration**:
   ```bash
   tofu state list
   ```

Benefits of migrating:
- ✅ Centralized state management
- ✅ Team collaboration
- ✅ Automated backups via S3 versioning
- ✅ Audit trail via CloudTrail

## Usage

### Deploy Bootstrap (GitHub Actions)

The GitHub Actions pipeline (`bootstrap-aws-001.yml`) automatically handles bootstrap deployment:

1. **Checks if bootstrap already exists** (S3 bucket + DynamoDB table)
2. **Skips deployment** if resources are present
3. **Deploys bootstrap** if resources are missing

To run manually:

```bash
# Navigate to bootstrap
cd infrastructure/Tofu/bootstrap

# Plan deployment
tofu plan -var-file=environments/part.tfvars

# Apply deployment
tofu apply -var-file=environments/part.tfvars
```

### Deploy Bootstrap (Azure DevOps)

The Azure DevOps pipeline (`aws-pipeline-bootstrap-001.yml`) provides the same functionality via PowerShell tasks.

### Deploy Bootstrap (Local)

For local development, ensure AWS credentials are configured:

```bash
# Set AWS credentials
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_REGION="eu-west-2"

# Initialize and deploy
cd infrastructure/Tofu/bootstrap
tofu init
tofu apply -var-file=environments/part.tfvars
```

## Configuration

### Customize for Your Environment

Edit `environments/part.tfvars`:

```hcl
# AWS Region
aws_region = "eu-west-2"

# Project and environment
project_name = "dpn"
environment  = "part"

# State storage
tfstate_bucket_name      = "dpn-tfstate-part-001"
tfstate_dynamodb_table   = "dpn-tfstate-lock"

# Security
enable_cloudtrail_audit       = true
enable_mfa_delete             = false
kms_key_deletion_window_days  = 7
```

### Key Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region for resources | `eu-west-2` |
| `project_name` | Project name for naming | `dpn` |
| `environment` | Environment name | `part` |
| `tfstate_bucket_name` | S3 bucket name | `dpn-tfstate-part-001` |
| `tfstate_dynamodb_table` | DynamoDB table name | `dpn-tfstate-lock` |
| `enable_cloudtrail_audit` | Enable CloudTrail logging | `true` |
| `enable_mfa_delete` | Enable MFA delete (requires MFA device) | `false` |

## Security Best Practices

### S3 State Bucket

✅ **Implemented:**
- Versioning enabled for state history
- Server-side encryption with AWS KMS
- Public access blocked
- Access logging enabled
- Bucket policy enforces TLS and correct KMS key
- All uploads must use encryption

### KMS Encryption

✅ **Implemented:**
- Dedicated KMS key for state encryption
- Automatic key rotation enabled
- 7-day deletion window (prevent accidental deletion)

### DynamoDB State Lock

✅ **Implemented:**
- Encryption enabled with AWS KMS
- Point-in-time recovery enabled
- DynamoDB Streams enabled for audit trail
- On-demand billing (pay per request)

### Audit & Compliance

✅ **Implemented:**
- CloudTrail enabled for all S3 and DynamoDB actions
- Separate S3 bucket for audit logs
- CloudWatch logs retention: 30 days
- All changes are auditable and traceable

### Additional Security Measures

Consider enabling these for production:

```hcl
# In environments/part.tfvars

# Enable MFA delete (requires MFA device)
enable_mfa_delete = true

# Increase log retention
log_retention_days = 90

# Increase KMS key deletion window
kms_key_deletion_window_days = 30
```

## Outputs

After deployment, the bootstrap provides outputs for configuring the main infrastructure:

```bash
# View all outputs
tofu output

# Get backend configuration
tofu output backend_config_hcl
```

Key outputs:
- `tfstate_bucket_name` - S3 bucket for main infrastructure state
- `tfstate_dynamodb_table_name` - DynamoDB table for state locking
- `backend_config_hcl` - HCL snippet for main infrastructure

## Troubleshooting

### S3 Bucket Already Exists

If you get an error that the bucket name is taken:

```
Error: Error creating S3 bucket: BucketAlreadyOwnedByYou
```

1. Update `tfstate_bucket_name` in `environments/part.tfvars`
2. Use a globally unique name (S3 bucket names must be globally unique)

### CloudTrail Fails to Create

If CloudTrail deployment fails:

1. Verify the audit bucket is correctly configured
2. Check IAM permissions for CloudTrail
3. Disable CloudTrail by setting:
   ```hcl
   enable_cloudtrail_audit = false
   ```

### DynamoDB Table Already Exists

If the table already exists, you can import it:

```bash
tofu import aws_dynamodb_table.tfstate_lock dpn-tfstate-lock
```

## Next Steps

After bootstrap deployment:

1. ✅ **Bootstrap deployed** - S3 bucket and DynamoDB table created
2. 📝 **Configure main infrastructure** - Update `infrastructure/Tofu/backend.tf` with outputs
3. 🚀 **Deploy main infrastructure** - Run `part-aws-001` workflow

### Configure Main Infrastructure Backend

Use the `backend_config_hcl` output to update `infrastructure/Tofu/backend.tf`:

```bash
# Example - run this after bootstrap deployment
tofu output backend_config_hcl
```

Output:
```hcl
terraform {
  backend "s3" {
    bucket         = "dpn-tfstate-part-001"
    key            = "part/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "dpn-tfstate-lock"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:eu-west-2:123456789012:key/..."
  }
}
```

## Maintenance

### Update Configuration

To modify bootstrap configuration:

1. **Update `environments/part.tfvars`**
2. **Run plan to review changes**:
   ```bash
   tofu plan -var-file=environments/part.tfvars
   ```
3. **Apply changes**:
   ```bash
   tofu apply -var-file=environments/part.tfvars
   ```

### Add New Environment

To bootstrap a new environment (e.g., production):

1. **Create new tfvars file**:
   ```bash
   cp environments/part.tfvars environments/prod.tfvars
   ```
2. **Update values** in `environments/prod.tfvars`
3. **Deploy**:
   ```bash
   tofu apply -var-file=environments/prod.tfvars
   ```

### Migrate State to S3 (Optional)

After bootstrap deployment, optionally migrate state to S3:

1. Uncomment S3 backend block in `backend-bootstrap.tf`
2. Run `tofu init`
3. Confirm migration

### Monitor State Access

View audit logs via CloudWatch:

```bash
# View recent log events
aws logs tail /aws/tfstate/part/audit --follow
```

## References

- [OpenTofu Backends](https://opentofu.org/docs/language/settings/backends/)
- [AWS S3 Backend Configuration](https://registry.opentofu.org/providers/hashicorp/aws/latest/docs/backends/types/s3)
- [OpenTofu State Locking](https://opentofu.org/docs/language/state/locking/)
- [AWS KMS](https://docs.aws.amazon.com/kms/)
- [AWS DynamoDB](https://docs.aws.amazon.com/dynamodb/)
