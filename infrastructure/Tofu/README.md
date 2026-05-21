# DPN AWS OpenTofu Baseline

This folder provides an AWS infrastructure codebase that mirrors the existing Azure OpenTofu structure and aligns with the DPN production HLD for EKS on AWS.

## Structure

- `main.tf`: Root orchestration of all infrastructure modules.
- `variables.tf`: Root input contract.
- `outputs.tf`: Root outputs.
- `providers.tf`: AWS and TLS providers.
- `backend.tf`: S3 backend template.
- `environments/`: Environment tfvars files.
- `modules/`: Reusable AWS infrastructure modules.

## Modules

- `networking`: VPC tiers, route tables, NAT, TGW attachment, Network Firewall, SGs, NACLs.
- `security`: KMS keys and IAM roles for EKS/SSM baseline.
- `observability`: CloudWatch log groups and optional S3 log buckets.
- `container_registry`: ECR repository with immutable tags and scanning.
- `eks`: EKS cluster, node groups, OIDC provider for IRSA.
- `ingress`: Public ALB, ACM certificate, Route53 alias, optional WAF.
- `database`: Private Multi-AZ RDS PostgreSQL baseline.
- `workload_identity`: IRSA role bindings per Kubernetes service account.

## HLD Mapping

This baseline implements the core pathing and controls from the target architecture:

- Ingress plane: Internet -> Route53 -> ALB -> Kubernetes ingress path.
- Egress plane: App subnet -> TGW -> Network Firewall -> NAT -> IGW.
- Zero-trust ops: SSM-enabled node role, no SSH required.
- Security by default: private EKS endpoint, KMS encryption, WAF and firewall controls.

## Quick Start

1. Set backend configuration in `backend.tf` or via `-backend-config`.
2. Update `environments/part.tfvars` with your environment values.
3. Run:

```bash
tofu init
tofu fmt -recursive
tofu validate
tofu plan -var-file=environments/part.tfvars
```
