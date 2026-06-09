# NESO DSI DPN Infrastructure - AWS Deployment Guide

**Production Reference Architecture for AWS EKS-based Kubernetes Deployments**

This comprehensive guide walks you through deploying a secure, scalable, and compliant AWS infrastructure using OpenTofu infrastructure-as-code.

---

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [Architecture Overview](#architecture-overview)
3. [Prerequisites](#prerequisites)
4. [Repository Structure](#repository-structure)
5. [Step-by-Step Deployment](#step-by-step-deployment)
6. [Configuration Guide](#configuration-guide)
7. [Security & Compliance](#security--compliance)
8. [Cost Management](#cost-management)
9. [Troubleshooting](#troubleshooting)
10. [Post-Deployment](#post-deployment)
11. [Support & Maintenance](#support--maintenance)

---

## Quick Start

### For Experienced Users (5 minutes)

```bash
# 1. Clone and navigate
git clone <repository-url>
cd infrastructure/Tofu

# 2. Bootstrap AWS state management
cd bootstrap
tofu init
tofu apply -var-file=environments/part.tfvars

# 3. Deploy main infrastructure
cd ../
tofu init -backend-config="bucket={state-bucket}" -backend-config="key=part" -backend-config="dynamodb_table={lock-table}"
tofu apply -var-file=environments/part.tfvars

# 4. Configure kubectl
aws eks update-kubeconfig --name dpn-eks-part --region eu-west-2
kubectl get nodes
```

### For First-Time Users
Proceed to [Step-by-Step Deployment](#step-by-step-deployment) section below.

---

## Architecture Overview

### High-Level Design

```
┌─────────────────────────────────────────────────────────┐
│                    AWS ACCOUNT                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  NETWORKING (VPC: 10.120.0.0/16)               │  │
│  │  ├─ Public Subnets (3 AZs)                      │  │
│  │  ├─ App Subnets (3 AZs)                         │  │
│  │  ├─ Data Subnets (3 AZs)                        │  │
│  │  ├─ Network Firewall → NAT Gateway → IGW       │  │
│  │  └─ VPC Endpoints (9 services)                  │  │
│  └──────────────────────────────────────────────────┘  │
│                        │                               │
│                        ▼                               │
│  ┌──────────────────────────────────────────────────┐  │
│  │  COMPUTE (EKS Cluster)                          │  │
│  │  ├─ Private API Endpoint                         │  │
│  │  ├─ System Node Group (t3.medium, 2 nodes)     │  │
│  │  ├─ App Node Group (optional)                   │  │
│  │  ├─ IRSA (IAM Roles for Service Accounts)      │  │
│  │  └─ Auto-scaling enabled                        │  │
│  └──────────────────────────────────────────────────┘  │
│                        │                               │
│  ┌──────────────────────────────────────────────────┐  │
│  │  INGRESS (Public Access)                        │  │
│  │  ├─ ALB with WAF v2                             │  │
│  │  ├─ ACM Certificate (auto-renewal)             │  │
│  │  ├─ Route53 DNS                                 │  │
│  │  └─ 3 Custom WAF Rules                          │  │
│  └──────────────────────────────────────────────────┘  │
│                        │                               │
│  ┌──────────────────────────────────────────────────┐  │
│  │  DATA SERVICES                                  │  │
│  │  ├─ RDS PostgreSQL (Multi-AZ, 100-500GB)      │  │
│  │  ├─ ECR Container Registry                      │  │
│  │  ├─ Secrets Manager                             │  │
│  │  └─ KMS Encryption Keys                         │  │
│  └──────────────────────────────────────────────────┘  │
│                        │                               │
│  ┌──────────────────────────────────────────────────┐  │
│  │  COMPLIANCE & OBSERVABILITY                     │  │
│  │  ├─ GuardDuty (threat detection)               │  │
│  │  ├─ Security Hub (findings)                     │  │
│  │  ├─ CloudTrail (audit logs)                     │  │
│  │  ├─ AWS Config (compliance rules)               │  │
│  │  ├─ CloudWatch Logs (VPC, EKS, ALB, WAF)      │  │
│  │  └─ Session Manager audit logging               │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Key Architectural Decisions

| Component | Choice | Rationale |
|-----------|--------|-----------|
| **IaC Tool** | OpenTofu | Terraform alternative, vendor-neutral, no licensing |
| **Kubernetes** | EKS 1.33 | Managed control plane, AWS-native, high availability |
| **Networking** | Custom VPC | Full control, compliance requirements, multi-AZ |
| **Database** | RDS PostgreSQL | Managed, Multi-AZ failover, automatic backups |
| **Container Registry** | ECR | AWS-native, secure, integrated with EKS |
| **Identity** | IRSA | Pod-level IAM, no long-lived credentials |
| **Secrets** | Secrets Manager | Encryption, rotation, audit trail |
| **Ingress** | ALB + WAF | L7 load balancing, DDoS protection, cost-effective |
| **Observability** | CloudWatch | Centralized logs, AWS-native, cost-effective |
| **Security** | GuardDuty + Config | Threat detection, compliance automation |

---

## Prerequisites

### Required Tools

```bash
# 1. OpenTofu CLI (Infrastructure as Code)
# Download from: https://opentofu.org/docs/intro/install/
tofu version  # Should show v1.9.0 or later

# 2. AWS CLI v2 (AWS API access)
# Download from: https://aws.amazon.com/cli/
aws --version  # Should show v2.x.x

# 3. kubectl (Kubernetes management)
# Download from: https://kubernetes.io/docs/tasks/tools/
kubectl version --client  # Should show v1.28+

# 4. Git (version control)
git --version  # Should show v2.x.x

# 5. jq (JSON processing - optional but recommended)
jq --version
```

### AWS Account Requirements

- **AWS Account**: Production or dedicated environment
- **IAM Permissions**: Administrator or equivalent permissions
  - VPC, EC2, EKS, RDS, CloudWatch, IAM, KMS, S3, CloudTrail, Config, GuardDuty
- **Service Quotas**: Check region eu-west-2 (London)
  - EKS clusters: ≥1
  - EC2 instances: ≥10 (for Auto Scaling Group)
  - RDS instances: ≥1
  - VPC Elastic IPs: ≥3 (for NAT Gateways)
  - VPC/Security Groups: Standard limits
- **IAM User or Role**: With programmatic access (Access Key ID + Secret Access Key)
- **AWS Region**: eu-west-2 (London) - configurable in variables

### AWS Credentials Setup

```bash
# Option 1: Using AWS CLI
aws configure
# Enter:
#   AWS Access Key ID: [your-access-key]
#   AWS Secret Access Key: [your-secret-key]
#   Default region: eu-west-2
#   Default output format: json

# Option 2: Using Environment Variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="eu-west-2"

# Option 3: Using AWS SSO (Recommended for enterprise)
aws sso login --profile prod
export AWS_PROFILE=prod

# Verify credentials
aws sts get-caller-identity
```

### Network Requirements

- **Outbound Internet Access**: For downloading Kubernetes components, container images
- **No Corporate Firewall Restrictions**: On AWS API endpoints, ECR endpoints
- **Domain Registration**: For Route53 DNS (separate process)

## Repository Structure

```
infrastructure/
├── Tofu/                           # Main IaC code
│   ├── backend.tf                  # Backend configuration (S3 + DynamoDB)
│   ├── main.tf                     # Root module orchestration
│   ├── variables.tf                # Input variables
│   ├── outputs.tf                  # Root module outputs
│   ├── providers.tf                # AWS provider config
│   ├── README.md                   # This deployment guide
│   │
│   ├── bootstrap/                  # State management bootstrap
│   │   ├── main.tf                 # S3, DynamoDB, KMS, CloudTrail
│   │   ├── variables.tf            # Bootstrap variables
│   │   ├── outputs.tf              # Backend outputs
│   │   ├── backend-bootstrap.tf    # Local backend for bootstrap
│   │   ├── README.md               # Bootstrap guide
│   │   └── environments/
│   │       └── part.tfvars         # Bootstrap configuration
│   │
│   ├── modules/                    # Reusable infrastructure modules
│   │   ├── security/               # KMS + IAM roles
│   │   ├── observability/          # CloudWatch logs + S3 buckets
│   │   ├── networking/             # VPC + subnets + VPC endpoints
│   │   ├── container_registry/     # ECR repository
│   │   ├── eks/                    # EKS cluster + node groups
│   │   ├── ingress/                # ALB + WAF + Route53
│   │   ├── database/               # RDS PostgreSQL
│   │   ├── workload_identity/      # IRSA for pod-level IAM
│   │   └── compliance/             # GuardDuty + Security Hub + Config
│   │
│   └── environments/
│       └── part.tfvars             # Production configuration
│
├── .github/workflows/              # GitHub Actions CI/CD
│   ├── bootstrap-aws-001.yml       # Bootstrap pipeline
│   └── part-aws-001.yml            # Main deployment pipeline
│
└── .azure-pipelines/               # Azure DevOps CI/CD
    ├── aws-pipeline-bootstrap-001.yml
    └── aws-pipeline-part-001.yml
```

### Module Descriptions

| Module | Purpose | Key Resources |
|--------|---------|---------------|
| **security** | KMS encryption keys, IAM roles | KMS key, EKS cluster role, EKS node role |
| **observability** | CloudWatch logs, S3 buckets | 8 log groups, 3 S3 buckets |
| **networking** | VPC, subnets, endpoints | VPC, 18 subnets, 9 VPC endpoints, NAT Gateways |
| **container_registry** | ECR repository | ECR with scanning and lifecycle policies |
| **eks** | EKS cluster, node groups | EKS cluster 1.33, system node group, OIDC provider |
| **ingress** | ALB, WAF, DNS | ALB, WAFv2, ACM certificate, Route53 |
| **database** | RDS PostgreSQL | Multi-AZ RDS, parameter groups, option groups |
| **workload_identity** | Pod-level IAM | OIDC provider, IRSA roles |
| **compliance** | Governance, audit | GuardDuty, Security Hub, CloudTrail, Config |

---

## Step-by-Step Deployment

### Phase 1: Prerequisites & Preparation (15 minutes)

#### 1.1 Install Required Tools

```bash
# Verify all tools are installed
tofu version
aws --version
kubectl version --client
git --version
jq --version  # Optional

# Install missing tools as needed
# Instructions: https://opentofu.org/docs/intro/install/
```

#### 1.2 Configure AWS Credentials

```bash
# Method 1: AWS CLI (interactive)
aws configure

# Verify credentials work
aws sts get-caller-identity
# Output should show your Account ID and ARN

# Verify region is set
aws configure get region  # Should output: eu-west-2
```

#### 1.3 Clone Repository

```bash
git clone <repository-url>
cd NESO-DSI-DPN-INFRA-PART_AWS
ls -la
# You should see:
#   infrastructure/
#   README.md (this file)
#   .github/
#   .azure-pipelines/
```

#### 1.4 Verify Repository Structure

```bash
# Navigate to Tofu directory
cd infrastructure/Tofu

# List modules
ls -la modules/
# Should show: compliance, container_registry, database, eks, ingress, 
#              networking, observability, security, workload_identity

# Check environment config exists
ls -la environments/part.tfvars
```

---

### Phase 2: Bootstrap AWS State Management (10 minutes)

The bootstrap phase creates S3 bucket and DynamoDB table for managing OpenTofu state remotely.

#### 2.1 Navigate to Bootstrap

```bash
cd infrastructure/Tofu/bootstrap
pwd  # Verify: .../infrastructure/Tofu/bootstrap
```

#### 2.2 Initialize Bootstrap

```bash
# Initialize OpenTofu (uses local backend initially)
tofu init

# Output should show:
# Initializing the backend...
# Terraform has been successfully configured!
```

#### 2.3 Review Bootstrap Plan

```bash
# Review what will be created
tofu plan -var-file=environments/part.tfvars

# Output shows:
#   aws_s3_bucket (state bucket)
#   aws_dynamodb_table (lock table)
#   aws_kms_key (encryption key)
#   aws_cloudtrail (audit logging)
#   ~15 resources total
```

#### 2.4 Apply Bootstrap

```bash
# Create S3 bucket, DynamoDB table, KMS key
tofu apply -var-file=environments/part.tfvars

# Type: yes to confirm

# Output shows:
#   Outputs:
#   state_bucket_name = "dpn-state-{account-id}"
#   lock_table_name = "dpn-lock-{account-id}"
#   backend_config = "..."
```

#### 2.5 Save Bootstrap Outputs

```bash
# Save outputs for next phase
tofu output -raw backend_config > backend_config.txt

# Display backend config
cat backend_config.txt
# Output:
#   bucket="dpn-state-..."
#   dynamodb_table="dpn-lock-..."
#   key="part"
#   region="eu-west-2"
```

#### 2.6 (Optional) Bootstrap Validation

```bash
# Verify S3 bucket was created
aws s3 ls | grep dpn-state

# Verify DynamoDB table was created
aws dynamodb list-tables | grep dpn-lock

# Verify KMS key was created
aws kms describe-key --key-id alias/dpn-state
```

---

### Phase 3: Main Infrastructure Deployment (30 minutes)

#### 3.1 Navigate to Main Infrastructure

```bash
cd ../  # Back to infrastructure/Tofu
pwd    # Verify: .../infrastructure/Tofu
```

#### 3.2 Configure Backend

```bash
# Read bootstrap outputs
cat bootstrap/backend_config.txt

# Extract values (or copy from bootstrap output)
# Example:
export BUCKET="dpn-state-123456789012"
export TABLE="dpn-lock-123456789012"

# Initialize with remote backend
tofu init \
  -backend-config="bucket=${BUCKET}" \
  -backend-config="dynamodb_table=${TABLE}" \
  -backend-config="key=part" \
  -backend-config="region=eu-west-2"

# Type: yes to confirm backend migration
# Output: Successfully configured backend
```

#### 3.3 Review Configuration

```bash
# Review current configuration
cat environments/part.tfvars | head -20

# Key settings should show:
#   project_name = "dpn"
#   environment = "part"
#   aws_region = "eu-west-2"
#   Enable all security features
```

#### 3.4 Validate Syntax

```bash
# Validate OpenTofu syntax
tofu validate

# Output should show:
# Success! The configuration is valid.
```

#### 3.5 Review Deployment Plan

```bash
# Generate execution plan (detailed)
tofu plan -var-file=environments/part.tfvars -out=tfplan

# This will output:
# - 9 modules loading
# - ~150+ resources to create
# - Takes ~2-3 minutes to evaluate
# - Save plan to tfplan file for apply phase

# Review specific resource types
tofu plan -var-file=environments/part.tfvars | grep -E "aws_eks|aws_rds|aws_lb"
```

#### 3.6 Apply Infrastructure

```bash
# Deploy infrastructure (uses plan file)
tofu apply tfplan

# Or apply with automatic planning
tofu apply -var-file=environments/part.tfvars

# Type: yes to confirm
# Takes ~20-30 minutes to complete
# Watch for:
#   EKS cluster creation (~15 min)
#   RDS database creation (~10 min)
#   VPC and subnets (~2 min)
```

#### 3.7 Monitor Deployment

```bash
# In another terminal, monitor AWS creation
# Watch EKS cluster status
aws eks describe-cluster --name dpn-eks-part --region eu-west-2 | jq .cluster.status

# Watch RDS database status
aws rds describe-db-instances --db-instance-identifier dpn-db-postgres-part | jq .DBInstances[0].DBInstanceStatus

# Watch EC2 instances
aws ec2 describe-instances --region eu-west-2 | jq '.Reservations[].Instances[] | {InstanceId, State}'
```

#### 3.8 Capture Outputs

```bash
# Save infrastructure outputs
tofu output > infrastructure_outputs.json

# Key outputs to save:
#   eks_cluster_id
#   eks_cluster_endpoint
#   database_endpoint
#   alb_dns_name
#   database_secret_arn

# Display specific outputs
tofu output -json | jq '.eks_cluster_id.value'
tofu output -json | jq '.alb_dns_name.value'
```

#### 3.9 Deployment Validation

```bash
# Verify EKS cluster is accessible
aws eks update-kubeconfig --name dpn-eks-part --region eu-west-2

# Test kubectl connectivity
kubectl cluster-info

# View nodes
kubectl get nodes
# Output should show:
#   2 nodes in Ready state
#   t3.medium instances
#   System taints applied

# Verify system pods
kubectl get pods -n kube-system
# Should show: coredns, kube-proxy, aws-node, etc.
```

---

## Configuration Guide

### Customizing Environment Configuration

All configuration is in `infrastructure/Tofu/environments/part.tfvars`:

```hcl
# Project identification
project_name = "dpn"         # Your project prefix
environment  = "part"        # Environment name (dev, staging, prod)
aws_region   = "eu-west-2"   # AWS region

# VPC Configuration
vpc_cidr = "10.120.0.0/16"   # VPC CIDR block (must be /16)

# EKS Configuration
kubernetes_version = "1.33"   # EKS version
system_node_count  = 2        # Minimum system nodes
system_node_type   = "t3.medium"

# RDS Configuration
db_instance_type     = "db.m6i.large"
db_allocated_storage = 100     # GB
db_max_allocated_storage = 500 # GB (auto-scaling)
db_backup_retention  = 35      # days

# Security & Compliance
enable_vpc_endpoints             = true
enable_restrictive_endpoint_policies = true
enable_session_manager_preferences  = true
enable_guardduty                 = true
enable_security_hub              = true
enable_cloudtrail                = true
enable_aws_config                = true

# WAF Configuration
blocked_country_codes         = ["KP", "IR", "SY"]
waf_allowed_http_methods      = ["GET", "POST", "PUT", "DELETE", "HEAD", "OPTIONS", "PATCH"]
waf_blocked_user_agent_regexes = ["sqlmap", "nikto", "nessus"]

# Logging & Retention
cloudtrail_retention_days = 90
log_retention_days        = 30

# Session Manager
ssm_session_timeout = 3600  # 60 minutes
```

### Adjusting Resource Sizing

To resize nodes or databases:

```bash
# Option 1: Edit tfvars file
vi environments/part.tfvars
# Change: system_node_type = "t3.large"

# Option 2: Use CLI override
tofu apply \
  -var-file=environments/part.tfvars \
  -var="system_node_type=t3.large"

# Changes are applied automatically with zero downtime
```

### Adding Custom Tags

```hcl
# Edit variables.tf to add tags
common_tags = {
  Project     = "NESO-DSI"
  Environment = "prod"
  CostCenter  = "12345"
  Owner       = "platform-team@example.com"
  ManagedBy   = "OpenTofu"
}
```

---

## Security & Compliance

### Built-in Security Controls

#### Network Security
- ✅ **Private EKS API Endpoint**: Cluster not exposed to internet
- ✅ **VPC Endpoints**: Private access to AWS services without internet
- ✅ **Network Firewall**: Ingress/egress filtering
- ✅ **WAF v2**: DDoS and web attack protection
- ✅ **Security Groups**: Least-privilege port access
- ✅ **NACLs**: Network-level access control

#### Identity & Access
- ✅ **IAM Roles**: Least-privilege roles per component
- ✅ **IRSA**: Pod-level IAM permissions (no long-lived keys)
- ✅ **OIDC Provider**: Token-based pod authentication
- ✅ **Session Manager**: Audit-logged SSH replacement
- ✅ **No EC2 Key Pairs**: SSH disabled on all instances

#### Data Security
- ✅ **KMS Encryption**: All data encrypted at rest
- ✅ **Encryption in Transit**: TLS 1.2+ for all connections
- ✅ **Secrets Manager**: Encrypted database credentials
- ✅ **RDS Encryption**: Multi-AZ encrypted database
- ✅ **EBS Encryption**: All EC2 volumes encrypted

#### Compliance & Audit
- ✅ **CloudTrail**: Complete audit trail of all API calls
- ✅ **GuardDuty**: Threat detection enabled
- ✅ **Security Hub**: Centralized security findings
- ✅ **AWS Config**: Compliance rules (7 active)
- ✅ **CloudWatch Logs**: 30-day retention with encryption

### Additional Security Hardening

```bash
# Enable GuardDuty findings export to S3
aws guardduty create-publishing-destination \
  --detector-id {detector-id} \
  --destination-type S3 \
  --destination-properties DestinationArn=arn:aws:s3:::findings

# Enable AWS Config aggregation (for multi-account)
aws configservice put-configuration-aggregator

# Set up Security Hub integrations
aws securityhub create-insight --name "Critical Findings"
```

### Compliance Certifications

This architecture supports:
- ✅ **ISO 27001** - Information security
- ✅ **SOC 2** - Security and availability
- ✅ **HIPAA** - Healthcare data (with additional config)
- ✅ **GDPR** - Data residency (eu-west-2)
- ✅ **PCI-DSS** - Payment data (with additional config)

### Scanning for Vulnerabilities

```bash
# Check for ECR image vulnerabilities
aws ecr start-image-scan \
  --repository-name dpn/workloads/part \
  --image-id imageTag=latest

# View scan results
aws ecr describe-image-scan-findings \
  --repository-name dpn/workloads/part \
  --image-id imageTag=latest

# Check AWS Config compliance
aws configservice get-compliance-details-by-config-rule \
  --config-rule-name ec2-imdsv2-check

# Run Prowler for comprehensive security audit
prowler aws --region eu-west-2
```

---

## Cost Management

### Cost Monitoring

```bash
# View costs in AWS Console
# https://console.aws.amazon.com/cost-management/home

# Query costs via CLI
aws ce get-cost-and-usage \
  --time-period Start=2026-05-01,End=2026-05-31 \
  --granularity MONTHLY \
  --metrics BlendedCost

# Export costs to CSV
aws ce get-cost-and-usage \
  --time-period Start=2026-05-01,End=2026-05-31 \
  --granularity DAILY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --output json | jq . > costs.json
```

### Cost Optimization Tips

| Optimization | Savings | Effort |
|---|---|---|
| Use Reserved Instances for EKS nodes | 40% | Medium |
| Right-size RDS (db.m6i.large vs t3) | 20% | Low |
| Enable RDS auto-scaling (100-500GB) | 10% | Low |
| Use Spot instances for app nodes | 60% | High |
| Consolidate workloads on fewer nodes | 15% | Medium |
| Archive CloudWatch logs after 30 days | 5% | Low |

### Cost Allocation Tags

Tag all resources for cost tracking:

```bash
# Apply cost allocation tags
aws ec2 create-tags \
  --resources i-1234567890abcdef0 \
  --tags Key=CostCenter,Value=12345 Key=Project,Value=NESO

# View costs by tag
aws ce get-cost-and-usage \
  --group-by Type=TAG,Key=Project
```

---

## Troubleshooting

### Common Issues

#### Issue 1: EKS API Endpoint Not Reachable

```bash
# Symptom: kubectl hangs or connection refused

# Solution 1: Verify kubectl config
kubectl config current-context

# Solution 2: Update kubeconfig
aws eks update-kubeconfig --name dpn-eks-part --region eu-west-2

# Solution 3: Check security groups
aws ec2 describe-security-groups \
  --filters Name=group-name,Values=dpn-eks-cluster-sg

# Solution 4: Verify VPC endpoint is available
aws ec2 describe-vpc-endpoints \
  --filters Name=service-name,Values='com.amazonaws.eu-west-2.eks'
```

#### Issue 2: RDS Connection Fails

```bash
# Symptom: Cannot connect to database

# Solution 1: Get RDS endpoint
tofu output database_endpoint

# Solution 2: Check security group
aws ec2 describe-security-groups --group-names dpn-db-sg

# Solution 3: Verify database is running
aws rds describe-db-instances \
  --db-instance-identifier dpn-db-postgres-part \
  --query 'DBInstances[0].DBInstanceStatus'

# Solution 4: Check credentials
aws secretsmanager get-secret-value \
  --secret-id dpn/part/rds/password
```

#### Issue 3: Nodes Stuck in NotReady State

```bash
# Symptom: kubectl get nodes shows NotReady

# Solution 1: Check node status
aws ec2 describe-instance-status \
  --instance-ids i-1234567890abcdef0

# Solution 2: View kubelet logs
aws ssm start-session --target i-1234567890abcdef0
sudo journalctl -u kubelet -n 100

# Solution 3: Verify IAM role
aws iam get-role-policy \
  --role-name dpn-eks-node-role-part \
  --policy-name EKSWorkerNodePolicy

# Solution 4: Restart node
aws ec2 reboot-instances --instance-ids i-1234567890abcdef0
```

#### Issue 4: WAF Blocking Legitimate Traffic

```bash
# Symptom: Requests blocked with 403

# Solution 1: Check WAF logs
aws logs tail /aws/wafv2/dpn-part --follow

# Solution 2: View blocked requests
aws wafv2 get-sampled-requests \
  --web-acl-arn arn:aws:wafv2:eu-west-2:...:global/webacl/dpn-waf-part \
  --rule-metric-name dpn-waf-part \
  --scope CLOUDFRONT \
  --time-window StartTime=...,EndTime=...

# Solution 3: Disable specific rule temporarily
aws wafv2 update-web-acl \
  --name dpn-waf-part \
  --region eu-west-2 \
  --override-action NONE
```

#### Issue 5: Deployment Stuck or Slow

```bash
# Symptom: tofu apply takes >30 minutes

# Solution 1: View activity logs
aws cloudtrail lookup-events --max-results 50

# Solution 2: Check AWS service health
aws health describe-events

# Solution 3: Monitor specific resource
aws ec2 describe-instances \
  --filters Name=tag:Project,Values=dpn \
  --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name}'

# Solution 4: Enable debug logging
TF_LOG=DEBUG tofu apply -var-file=environments/part.tfvars
```

### Getting Support

1. **Check Logs**: CloudWatch Logs contain detailed error messages
2. **Review Outputs**: Validate infrastructure outputs are correct
3. **Verify Permissions**: Ensure IAM user/role has all required permissions
4. **Check AWS Service Status**: Some issues are service-wide
5. **Contact AWS Support**: For infrastructure issues
6. **Review Module Documentation**: Each module has troubleshooting guide

---

## Post-Deployment

### Immediate Post-Deployment Tasks (1 hour)

#### 1. Verify All Components

```bash
# EKS Cluster
kubectl get cluster-info
kubectl get nodes -o wide
kubectl get namespaces

# Database
psql -h {database-endpoint} -U admin -d postgres -c "SELECT version();"

# Container Registry
aws ecr describe-repositories

# Load Balancer
aws elbv2 describe-load-balancers \
  --names dpn-alb-part

# WAF
aws wafv2 list-web-acls --region eu-west-2
```

#### 2. Test Connectivity

```bash
# Test DNS resolution
nslookup {domain-name}

# Test ALB connectivity
curl -I https://{domain-name}

# Test EKS ingress
kubectl create service clusterip test --tcp=80:80
kubectl describe svc test
```

#### 3. Configure Monitoring Alerts

```bash
# Create CloudWatch alarm for high CPU
aws cloudwatch put-metric-alarm \
  --alarm-name dpn-high-cpu \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold

# Create alarm for RDS connections
aws cloudwatch put-metric-alarm \
  --alarm-name dpn-db-connections \
  --metric-name DatabaseConnections \
  --namespace AWS/RDS \
  --threshold 80
```

### Day 2 Operations

#### Deploy Sample Application

```yaml
# Create namespace
kubectl create namespace demo

# Deploy sample app
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  namespace: demo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: demo
  template:
    metadata:
      labels:
        app: demo
    spec:
      serviceAccountName: demo-sa
      containers:
      - name: app
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: demo-sa
  namespace: demo
```

#### Configure IRSA for Application

```bash
# Create IAM role for app
aws iam create-role \
  --role-name dpn-irsa-demo-app \
  --assume-role-policy-document '{...}'

# Attach policy
aws iam attach-role-policy \
  --role-name dpn-irsa-demo-app \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# Annotate ServiceAccount
kubectl annotate serviceaccount demo-sa \
  -n demo \
  eks.amazonaws.com/role-arn=arn:aws:iam::{account}:role/dpn-irsa-demo-app
```

### Ongoing Maintenance

```bash
# Update EKS cluster version (monthly)
aws eks update-cluster-version \
  --name dpn-eks-part \
  --kubernetes-version 1.34

# Update node AMI (monthly)
aws eks update-nodegroup-version \
  --cluster-name dpn-eks-part \
  --nodegroup-name system

# Rotate RDS master password (quarterly)
aws secretsmanager rotate-secret \
  --secret-id dpn/part/rds/password

# Review Security Hub findings (weekly)
aws securityhub get-insights

# Analyze costs (monthly)
# AWS Cost Management Console
```

---

## Support & Maintenance

### Documentation

Each infrastructure module has detailed documentation:

```
infrastructure/Tofu/modules/
├── security/README.md           # KMS keys, IAM roles
├── observability/README.md      # CloudWatch, S3 logging
├── networking/README.md         # VPC, subnets, endpoints
├── container_registry/README.md # ECR configuration
├── eks/README.md                # EKS cluster details
├── ingress/README.md            # ALB, WAF, DNS
├── database/README.md           # RDS, backups, failover
├── workload_identity/README.md  # IRSA, pod IAM
└── compliance/README.md         # GuardDuty, Config, CloudTrail
```

### CI/CD Pipeline Documentation

See [PIPELINES.md](./PIPELINES.md) for:
- GitHub Actions workflow
- Azure DevOps pipeline
- Automated testing and validation
- Approval gates and security checks

### Rollback Procedures

```bash
# Rollback to previous state
tofu destroy -var-file=environments/part.tfvars
# Type: yes to confirm

# Or selective rollback
tofu destroy -var-file=environments/part.tfvars \
  -target=module.ingress \
  -target=module.container_registry

# Recover from state file
aws s3 cp s3://{state-bucket}/part .terraform/terraform.tfstate
tofu refresh
```

### Getting Help

- **OpenTofu Docs**: https://opentofu.org/docs/
- **AWS Documentation**: https://docs.aws.amazon.com/
- **EKS Documentation**: https://docs.aws.amazon.com/eks/latest/userguide/
- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **Community**: AWS forums, Kubernetes Slack, OpenTofu discussions

### Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | May 2026 | Initial production release |
| | | 9 infrastructure modules |
| | | CI/CD automation (GitHub + Azure DevOps) |
| | | Comprehensive security controls |

---

## Summary

This deployment guide provides everything needed to successfully deploy and maintain a production-grade AWS infrastructure using OpenTofu. The architecture emphasizes:

✅ **Security** - Encryption, least-privilege, audit trails
✅ **Compliance** - 7 AWS Config rules, GuardDuty, Security Hub
✅ **Scalability** - Auto-scaling nodes, RDS, ALB
✅ **Observability** - Centralized logging, monitoring, alerting
✅ **Cost-Effectiveness** - ~$975/month for enterprise infrastructure
✅ **Maintainability** - Well-documented modules, consistent patterns

**Next Steps:**
1. Review [Prerequisites](#prerequisites)
2. Follow [Step-by-Step Deployment](#step-by-step-deployment)
3. Configure environment in [Configuration Guide](#configuration-guide)
4. Implement security hardening in [Security & Compliance](#security--compliance)
5. Monitor costs using [Cost Management](#cost-management)
6. Use [Troubleshooting](#troubleshooting) for any issues

---

**Last Updated**: May 2026
**Maintained By**: Platform Engineering Team


## DEV deployment profile

A DEV profile has been added for first deployment testing:

```text
infrastructure/Tofu/environments/dev.tfvars
infrastructure/Tofu/bootstrap/environments/dev.tfvars
infrastructure/Tofu/backends/dev.hcl
```

First deploy bootstrap:

```bash
cd infrastructure/Tofu/bootstrap
tofu init
tofu apply -var-file=environments/dev.tfvars
```

Then run the main DEV plan:

```bash
cd infrastructure/Tofu
tofu init -backend-config=backends/dev.hcl
tofu plan -var-file=environments/dev.tfvars
```

See:

```text
docs/dev-deployment.md
```

## DEV EKS access and data bucket

The DEV configuration includes EKS Access Entries for the IAM Identity Center EKSAdmin and EKSDevOps roles.

The DEV configuration also creates a private encrypted DPN data bucket:

```text
dpn-dev-627657103820-eu-west-2-data
```

See `docs/dev-deployment.md` for the current DEV deployment parameters.
