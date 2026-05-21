# AWS Deployment Pipelines Guide

This directory contains CI/CD pipeline definitions for deploying AWS infrastructure using OpenTofu.

## Pipeline Structure

### GitHub Actions Workflows
Located in `.github/workflows/`

- **bootstrap-aws-001.yml** - Bootstrap pipeline for AWS S3/DynamoDB setup
- **part-aws-001.yml** - Main infrastructure deployment pipeline

### Azure DevOps Pipelines
Located in `.azure-pipelines/`

- **aws-pipeline-bootstrap-001.yml** - Bootstrap pipeline for Azure DevOps
- **aws-pipeline-part-001.yml** - Main infrastructure deployment for Azure DevOps

## Deployment Workflow

### Phase 1: Bootstrap Infrastructure
The bootstrap pipeline deploys OpenTofu code that creates the S3 backend:
1. **S3 Bucket** - Stores OpenTofu state files with encryption and versioning
2. **DynamoDB Table** - Enables state locking to prevent concurrent modifications
3. **KMS Key** - Encrypts state files with automatic rotation
4. **CloudTrail** - Audits all state access and changes
5. **CloudWatch Logs** - Monitors state operations

Bootstrap code: `infrastructure/Tofu/bootstrap/`

**Run this pipeline first before any infrastructure deployment.**

### Phase 2: Main Infrastructure Deployment
The part-aws-001 pipeline deploys the main AWS infrastructure:
1. **Validation** - Checks bootstrap prerequisites
2. **Quality Checks** - Runs fmt, validate, tflint, and tfsec
3. **Planning** - Generates OpenTofu plan
4. **Approval** - Manual approval step before apply
5. **Deployment** - Applies or destroys infrastructure

## GitHub Actions Setup

### 1. Create GitHub Secrets

Add the following secrets to your GitHub repository:

```
AWS_ACCOUNT_ID           - Your AWS account ID
AWS_ACCESS_KEY_ID        - AWS IAM user access key
AWS_SECRET_ACCESS_KEY    - AWS IAM user secret key
AWS_REGION               - Target AWS region (e.g., eu-west-2)
```

**Recommended:** Use AWS IAM roles with OIDC instead of access keys for better security.

### 2. Create GitHub Environments

Create two environments in your GitHub repository:

**bootstrap-aws-001** (for bootstrap workflow)
- No additional configuration needed

**part-aws-001-deploy** (for main infrastructure)
- Add required reviewers for manual approval
- Set deployment branches to: `main`, `development`

### 3. Create GitHub Variables

Add the following repository or environment variables:

```
OPENTOFU_VERSION         - OpenTofu version (e.g., 1.9.0)
TFSTATE_BUCKET_NAME      - S3 bucket name (e.g., dpn-tfstate-part-001)
TFSTATE_DYNAMODB_TABLE   - DynamoDB table name (e.g., dpn-tfstate-lock)
TFSTATE_KEY              - State file key (e.g., part/terraform.tfstate)
PROJECT_NAME             - Project name (e.g., dpn)
ENVIRONMENT              - Environment name (e.g., part)
```

### 4. Running the Workflows

**Bootstrap Workflow:**
1. Go to **Actions** → **Bootstrap Infrastructure (bootstrap-aws-001)**
2. Click **Run workflow**
3. Choose `what_if: true` for preview (default)
   - This runs `tofu plan` from `infrastructure/Tofu/bootstrap/`
4. Re-run with `what_if: false` to actually deploy
   - This runs `tofu apply` with `environments/part.tfvars`
5. **Copy backend output** from workflow logs
6. **Update** `infrastructure/Tofu/backend.tf` with the backend configuration

**Main Infrastructure:**
1. Go to **Actions** → **Infrastructure Deployment (part-aws-001)**
2. Click **Run workflow**
3. Choose action: `plan`, `apply`, or `destroy`
4. For PRs: Automatically runs plan on changes to infrastructure/

## Azure DevOps Setup

### 1. Create Variable Groups

Create a variable group named `dpn-aws-vars-001` with:

```
AGENT_POOL               - Azure DevOps agent pool name
SERVICE_CONNECTION_NAME  - AWS service connection name
AWS_ACCOUNT_ID           - AWS account ID
AWS_REGION               - Target AWS region (e.g., eu-west-2)
TFSTATE_BUCKET_NAME      - S3 bucket name
TFSTATE_DYNAMODB_TABLE   - DynamoDB table name
TFSTATE_KEY              - State file key
```

### 2. Create AWS Service Connection

1. Go to **Project Settings** → **Service Connections**
2. Create new **AWS** service connection
3. Name it `dpn-aws-001` (or as specified in `SERVICE_CONNECTION_NAME`)
4. Add AWS access key and secret

### 3. Configure Agent Pool

Ensure you have a self-hosted agent pool configured:
- Agent pool must have `git` and `python` installed
- For Windows agents: PowerShell 5.1+
- For Linux agents: Bash shell

### 4. Configure Approvals

For the deploy stage, set up manual approvals:
1. Go to **Pipelines** → **Environments**
2. Create environment: `part-aws-001-deploy`
3. Add approvers for infrastructure changes

### 5. Running the Pipelines

**Bootstrap Pipeline:**
1. Navigate to **Pipelines** → **aws-pipeline-bootstrap-001**
2. Click **Run pipeline**
3. Pipeline will:
   - Check if S3 bucket and DynamoDB table exist
   - Auto-skip if bootstrap already exists
   - Deploy `infrastructure/Tofu/bootstrap/` via `tofu apply`
   - Output backend configuration in logs
4. **Copy backend output** from pipeline logs
5. **Update** `infrastructure/Tofu/backend.tf` with the configuration

**Main Pipeline:**
1. Navigate to **Pipelines** → **aws-pipeline-part-001**
2. Click **Run pipeline**
3. Select action: `plan`, `apply`, or `destroy`
4. Approve in manual approval step before apply

## Backend Configuration

### Bootstrap Infrastructure (OpenTofu Code)

Bootstrap infrastructure is defined in `infrastructure/Tofu/bootstrap/`:

```
bootstrap/
├── main.tf                 # S3, DynamoDB, KMS, CloudTrail resources
├── variables.tf            # Input variables
├── outputs.tf              # Exported values (including backend config)
├── backend-bootstrap.tf    # Local state (or S3 after migration)
├── environments/
│   └── part.tfvars         # Bootstrap configuration
└── README.md               # Detailed documentation
```

**Key Features:**
- ✅ Versioning enabled on S3 bucket
- ✅ Encryption with AWS KMS and automatic key rotation
- ✅ Public access blocked
- ✅ Access logging enabled
- ✅ DynamoDB point-in-time recovery
- ✅ CloudTrail for audit logging

**Deploy bootstrap locally:**
```bash
cd infrastructure/Tofu/bootstrap
tofu init
tofu plan -var-file=environments/part.tfvars
tofu apply -var-file=environments/part.tfvars
```

**Get backend configuration from outputs:**
```bash
tofu output backend_config_hcl
```

Then copy the output and update `infrastructure/Tofu/backend.tf`.

### S3 Backend Setup

Create `infrastructure/Tofu/backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "dpn-tfstate-part-001"
    key            = "part/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "dpn-tfstate-lock"
    encrypt        = true
  }
}
```

**Override for local development:**
Create `infrastructure/Tofu/backend-override.tf` (in `.gitignore`):

```hcl
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
```

## Pipeline Features

### GitHub Actions

✅ **Automated on PR** - Runs plan automatically on pull requests
✅ **OIDC Support** - Can use AWS OIDC instead of access keys
✅ **PR Comments** - Posts plan summary as PR comments
✅ **Manual Approval** - Requires approval before apply via GitHub Environments
✅ **Concurrency Protection** - Prevents concurrent runs

### Azure DevOps

✅ **Manual Approval** - Integrated approval gates
✅ **Multi-stage Pipelines** - Organized stage-by-stage execution
✅ **Variable Groups** - Centralized variable management
✅ **Pipeline Artifacts** - Stores plan artifacts for audit trail
✅ **Lock Behavior** - Sequential execution to prevent conflicts

## Security Best Practices

### Credentials Management

**❌ DO NOT:**
- Commit AWS access keys to repository
- Store secrets in pipeline YAML files
- Use long-lived IAM user keys

**✅ DO:**
- Use GitHub Secrets for sensitive data
- Use AWS IAM roles with OIDC (GitHub Actions)
- Use temporary credentials with service connections (Azure DevOps)
- Rotate credentials regularly
- Use least-privilege IAM policies

### State Management

- S3 bucket has versioning enabled
- Encryption is enabled with AES256
- DynamoDB table prevents concurrent modifications
- Consider enabling MFA delete on S3 bucket for critical environments

### Code Quality

All pipelines run:
- **tofu fmt** - Code formatting check
- **tofu validate** - Configuration validation
- **tflint** - Terraform linting
- **tfsec** - Security scanning

## Common Tasks

### Run Plan Only

**GitHub:**
```
Action: plan
```

**Azure DevOps:**
```
Parameters: action = plan
```

### Apply Changes

**GitHub:**
```
Action: apply (requires approval in part-aws-001-deploy environment)
```

**Azure DevOps:**
```
Parameters: action = apply (requires approval in part-aws-001-deploy environment)
```

### Destroy Infrastructure

**GitHub:**
```
Action: destroy (requires approval)
```

**Azure DevOps:**
```
Parameters: action = destroy (requires approval)
```

### Force Unlock State

If a pipeline run is interrupted and state is locked:

**GitHub:**
```
force_unlock: true
lock_id: <ID from error message>
```

**Azure DevOps:**
```
forceUnlock: true
lockId: <ID from error message>
```

## Troubleshooting

### Bootstrap Deployment Issues

If bootstrap deployment fails:

1. **Verify OpenTofu syntax:**
   ```bash
   cd infrastructure/Tofu/bootstrap
   tofu init -backend=false
   tofu validate
   ```

2. **Check S3 bucket name conflicts:**
   - S3 bucket names are globally unique
   - If name is taken, update `TFSTATE_BUCKET_NAME` in pipeline variables
   - Edit `infrastructure/Tofu/bootstrap/environments/part.tfvars`

3. **Review bootstrap logs:**
   - GitHub: Check workflow logs for error details
   - Azure DevOps: Check pipeline logs for error details

4. **Common issues:**
   - Insufficient AWS permissions (ensure IAM role has S3, DynamoDB, KMS permissions)
   - Region constraints (some regions may have limited service availability)
   - Existing resources (if resources partially exist, import them)

### State Lock Issues

If you see "Error acquiring the state lock":
1. Check if another pipeline is running
2. Use force unlock option (with caution)
3. Verify DynamoDB table exists and is accessible

### Backend Configuration Errors

If backend initialization fails:
1. Verify S3 bucket exists and is accessible
2. Check DynamoDB table is active
3. Verify IAM permissions for the service principal/user

### Terraform Plan Errors

If plan fails:
1. Check variable files (infrastructure/Tofu/environments/part.tfvars)
2. Verify all required variables are set
3. Check AWS resource quotas and limits
4. Review AWS credentials and permissions

## Maintenance

### Bootstrap Configuration

Bootstrap is managed as code in `infrastructure/Tofu/bootstrap/`.

**To modify bootstrap configuration:**
1. Edit `infrastructure/Tofu/bootstrap/environments/part.tfvars`
2. Test locally:
   ```bash
   cd infrastructure/Tofu/bootstrap
   tofu plan -var-file=environments/part.tfvars
   ```
3. Commit changes to version control
4. Deploy via pipeline or manually: `tofu apply`

**Key configuration options:**
- `tfstate_bucket_name` - S3 bucket for state
- `tfstate_dynamodb_table` - DynamoDB table for locking
- `enable_cloudtrail_audit` - Enable audit logging
- `enable_mfa_delete` - Require MFA for deletion (production)

### Update OpenTofu Version

Update `OPENTOFU_VERSION` variable:
- **GitHub:** Repository variable
- **Azure DevOps:** Variable group `dpn-aws-vars-001`

### Add New Environments

To add a new environment (e.g., prod-001):

1. **Create bootstrap configuration:**
   ```bash
   cp infrastructure/Tofu/bootstrap/environments/part.tfvars \
      infrastructure/Tofu/bootstrap/environments/prod.tfvars
   ```
   Update bucket names and table names to be environment-specific

2. **Create new GitHub workflows:**
   ```bash
   cp .github/workflows/bootstrap-aws-001.yml \
      .github/workflows/bootstrap-aws-prod-001.yml
   cp .github/workflows/part-aws-001.yml \
      .github/workflows/part-aws-prod-001.yml
   ```
   Update environment names and variable references

3. **Create new Azure DevOps pipelines:**
   ```bash
   cp .azure-pipelines/aws-pipeline-bootstrap-001.yml \
      .azure-pipelines/aws-pipeline-bootstrap-prod-001.yml
   cp .azure-pipelines/aws-pipeline-part-001.yml \
      .azure-pipelines/aws-pipeline-part-prod-001.yml
   ```

4. **Create main infrastructure configuration:**
   ```bash
   cp infrastructure/Tofu/environments/part.tfvars \
      infrastructure/Tofu/environments/prod.tfvars
   ```

5. **Update service connections and variable groups** in Azure DevOps
6. **Add GitHub Secrets and Environments** for new environment
7. **Deploy bootstrap first**, then main infrastructure

## Documentation

- **OpenTofu Documentation**: https://opentofu.org/docs/
- **AWS Provider**: https://registry.opentofu.org/providers/hashicorp/aws
- **Infrastructure Code**: `infrastructure/Tofu/README.md`
