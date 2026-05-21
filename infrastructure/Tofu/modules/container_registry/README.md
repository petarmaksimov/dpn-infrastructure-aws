# Container Registry Module

## Overview

The container registry module creates an Elastic Container Registry (ECR) repository with security hardening:
- **ECR Repository** - Private container image registry
- **Image Scanning** - Automatic vulnerability scanning on push
- **Lifecycle Policies** - Automated cleanup of untagged images
- **Immutable Tags** - Prevent image tag overwriting
- **KMS Encryption** - All images encrypted at rest

## Architecture

```
┌────────────────────────────────────────────┐
│      Container Registry Module             │
├────────────────────────────────────────────┤
│                                            │
│  ┌──────────────────────────────────────┐ │
│  │ ECR Repository                       │ │
│  │ {project}/workloads/{environment}   │ │
│  │                                      │ │
│  │ Security Features:                   │ │
│  │ ├─ Immutable Tags                   │ │
│  │ ├─ Image Scanning (CVE detection)   │ │
│  │ ├─ KMS Encryption                   │ │
│  │ └─ Access Control (IAM)             │ │
│  └──────────────────────────────────────┘ │
│              ↓                             │
│  ┌──────────────────────────────────────┐ │
│  │ Lifecycle Policy                     │ │
│  │ └─ Delete untagged images after 7d  │ │
│  └──────────────────────────────────────┘ │
│                                            │
└────────────────────────────────────────────┘
```

## Resources Created

### ECR Repository

- **Name Pattern**: `{project}/workloads/{environment}`
  - Example: `dpn/workloads/part`
- **Image Tag Mutability**: Immutable (prevent overwrites)
- **Image Scanning**: Enabled (scans on push)
- **Encryption**: KMS key encryption
- **Lifecycle Policy**: Delete untagged images after 7 days

## Key Variables

- `project_name` - Project name (default: "dpn")
- `environment` - Environment name (default: "part")
- `image_tag_mutability` - IMMUTABLE or MUTABLE (default: IMMUTABLE)
- `scan_on_push` - Enable image scanning (default: true)
- `kms_key_arn` - KMS key for encryption (optional, uses AES256 if null)

## Outputs

- `repository_url` - ECR repository URL for pushing images
- `repository_arn` - ECR repository ARN
- `repository_name` - ECR repository name (e.g., dpn/workloads/part)
- `registry_id` - AWS account ID

## Usage Examples

### Push Images to ECR

```bash
# 1. Get login token
aws ecr get-login-password --region eu-west-2 | \
  docker login --username AWS --password-stdin {account-id}.dkr.ecr.eu-west-2.amazonaws.com

# 2. Build and tag image
docker build -t {repository-url}:1.0.0 .

# 3. Push to ECR
docker push {repository-url}:1.0.0
```

### View Image Scan Results

```bash
aws ecr describe-image-scan-findings \
  --repository-name dpn/workloads/part \
  --image-id imageTag=1.0.0
```

### Pull Images from EKS

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
  - name: app
    image: {account-id}.dkr.ecr.eu-west-2.amazonaws.com/dpn/workloads/part:1.0.0
```

## Lifecycle Policy

Default policy deletes:
- Untagged images after 7 days
- Keeps unlimited tagged images

Customize in tfvars or main.tf as needed.

## Security Best Practices

✅ **Implemented:**
- Immutable Tags - Prevent accidental overwrites
- Automatic Scanning - Detect vulnerabilities on push
- KMS Encryption - Images encrypted at rest
- Private Registry - No public access
- Lifecycle Policies - Automatic cleanup

## Image Scanning & Vulnerability Management

### Interpret Severity Levels

| Severity | Action |
|----------|--------|
| CRITICAL | Block deployment |
| HIGH | Fix before production |
| MEDIUM | Plan remediation |
| LOW | Monitor |

### Cost Optimization

- **Storage**: $0.10/GB-month
- **Use multi-stage builds** - Reduce image size
- **Aggressive lifecycle** - Delete images sooner
- **Share common layers** - Reuse base images

## Related Modules

- **Security** - Provides KMS key for encryption
- **EKS** - Pulls images from this registry
- **Workload Identity** - Provides IAM permissions

## References

- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [Image Scanning](https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-scanning.html)
- [Lifecycle Policies](https://docs.aws.amazon.com/AmazonECR/latest/userguide/lifecycle_policy_examples.html)
