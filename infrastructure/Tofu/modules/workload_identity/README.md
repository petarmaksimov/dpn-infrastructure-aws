# Workload Identity Module

## Overview

The workload identity module enables fine-grained IAM permissions for Kubernetes workloads using IRSA (IAM Roles for Service Accounts):
- **OIDC Provider** - Integration between EKS and AWS IAM
- **IAM Roles** - Per-namespace or per-workload roles
- **Service Accounts** - Kubernetes ServiceAccount with IAM role annotation
- **Pod IAM Credentials** - Automatically injected AWS credentials

## Key Features

- **OIDC Provider**: AWS STS endpoint for OIDC token exchange
- **IRSA**: No long-lived AWS credentials in pods
- **Least Privilege**: Per-workload IAM roles
- **Automatic Injection**: AWS SigV4 credentials via webhook
- **Audit Trail**: CloudTrail logs all credential usage
- **Namespace Scoped**: Trust limited to specific namespace:serviceaccount

## Resources Created

### OIDC Provider (Per Cluster)
- **Endpoint**: AWS STS endpoint for OIDC
- **Provider ARN**: `arn:aws:iam::{account}:oidc-provider/oidc.eks.region.amazonaws.com/id/{ID}`
- **Thumbprints**: AWS-managed certificate thumbprints
- **Trust Conditions**: Namespace:serviceaccount specific

### IAM Roles (Per Namespace/Workload)

Example:
- `dpn-irsa-default-app` - App namespace
- `dpn-irsa-kube-system-ebs-csi` - EBS CSI driver
- `dpn-irsa-{namespace}-{service}` - Custom workload

### ServiceAccount Annotations

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app
  namespace: default
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT:role/dpn-irsa-default-my-app
```

## Key Variables

- `cluster_name` - EKS cluster name
- `cluster_oidc_provider_arn` - OIDC provider ARN (from EKS)
- `cluster_oidc_issuer_url` - OIDC issuer URL (from EKS)
- `namespace` - Kubernetes namespace (default: "default")
- `service_account_name` - Service account name
- `project_name` - Project name (default: "dpn")
- `environment` - Environment (default: "part")
- `role_policy_document` - IAM policy JSON

## Outputs

- `oidc_provider_arn` - OIDC provider ARN
- `created_role_arn` - IAM role ARN
- `created_role_name` - IAM role name

## Usage Examples

### Create IRSA Role

```hcl
module "workload_identity" {
  source = "./modules/workload_identity"

  cluster_name              = module.eks.cluster_id
  cluster_oidc_provider_arn = module.eks.oidc_provider_arn
  cluster_oidc_issuer_url   = module.eks.cluster_oidc_issuer_url
  
  namespace             = "default"
  service_account_name  = "my-app"

  # S3 read-only policy
  role_policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = ["arn:aws:s3:::my-bucket", "arn:aws:s3:::my-bucket/*"]
      }
    ]
  })
}
```

### Create ServiceAccount

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app
  namespace: default
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT:role/dpn-irsa-default-my-app
```

### Use in Pod

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      serviceAccountName: my-app  # Uses IRSA annotation
      containers:
      - name: app
        image: my-image:latest
```

### Test IRSA

```bash
kubectl exec -it {pod-name} -- aws sts get-caller-identity
# Should show the role ARN
```

## Common Use Cases

### EBS CSI Driver
- Policy: Attach/detach EBS volumes
- Namespace: kube-system

### App with S3 Access
- Policy: GetObject, ListBucket
- Namespace: default (app)

### Cross-Account Role Assumption
- Policy: sts:AssumeRole to other account
- Namespace: Application namespace

## Security Best Practices

✅ **Implemented:**
- OIDC provider configured
- Trust limited to namespace:serviceaccount
- JWT audience enforcement
- Per-workload IAM roles
- Least-privilege policies
- No long-lived keys
- CloudTrail auditing

## Cost Optimization

- **OIDC Provider**: No cost
- **IAM Roles**: No cost per role
- **No key rotation overhead**: Short-lived tokens

## Troubleshooting

### Pod Cannot Assume Role

```bash
# Check ServiceAccount has annotation
kubectl describe sa my-app -n default

# Verify OIDC provider exists
aws iam list-open-id-connect-providers

# Check role trust relationship
aws iam get-role --role-name dpn-irsa-default-my-app
```

### Credentials Not Injected

```bash
# Verify webhook is running
kubectl get deployment -n kube-system aws-pod-identity-webhook

# Restart pod to trigger injection
kubectl rollout restart deployment/my-app -n default
```

### Permission Denied

```bash
# Test credential validity
aws sts get-caller-identity --profile {role-arn}

# Review role policy for resource ARNs
aws iam get-role-policy --role-name {role-name} --policy-name {policy-name}
```

## Dependencies

- **EKS Module** - Provides cluster and OIDC provider

## References

- [AWS IRSA Documentation](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
- [OIDC Overview](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts-technical-overview.html)
