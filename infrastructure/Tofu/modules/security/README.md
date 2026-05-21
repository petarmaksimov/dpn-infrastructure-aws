# Security Module

## Overview

The security module establishes the foundational security infrastructure for the AWS deployment, including:
- **KMS Key** - AWS Key Management Service key for encrypting sensitive data across all services
- **EKS Cluster IAM Role** - Service role that allows EKS control plane to manage AWS resources
- **EKS Node IAM Role** - Service role for EC2 instances running as Kubernetes nodes
- **IAM Policies** - Managed and custom policies for least-privilege access

## Architecture

```
┌─────────────────────────────────────────────┐
│         Security Module                     │
├─────────────────────────────────────────────┤
│                                             │
│  ┌────────────────────────────────────────┐ │
│  │ KMS Key (Encryption)                   │ │
│  │ ├─ Auto-rotation enabled               │ │
│  │ ├─ 30-day deletion window               │ │
│  │ └─ Used by: RDS, EBS, EKS, Secrets    │ │
│  └────────────────────────────────────────┘ │
│                                             │
│  ┌────────────────────────────────────────┐ │
│  │ EKS Cluster Role                       │ │
│  │ ├─ Service: eks.amazonaws.com          │ │
│  │ ├─ Policy: AmazonEKSClusterPolicy     │ │
│  │ └─ Allows EKS to manage AWS resources │ │
│  └────────────────────────────────────────┘ │
│                                             │
│  ┌────────────────────────────────────────┐ │
│  │ EKS Node Role                          │ │
│  │ ├─ Service: ec2.amazonaws.com          │ │
│  │ ├─ Policies: CNI, ECR, SSM, CloudWatch│ │
│  │ └─ Allows nodes to manage k8s resources│ │
│  └────────────────────────────────────────┘ │
│                                             │
└─────────────────────────────────────────────┘
```

## Resources Created

### KMS Key
- **Name Pattern**: `kms-{project}-core-{environment}`
- **Rotation**: Enabled (automatic yearly rotation)
- **Deletion Window**: 30 days
- **Alias**: `alias/{project}-{environment}-core`
- **Purpose**: Encrypts sensitive data in RDS, EBS, EKS, and other services

### EKS Cluster Role
- **Name Pattern**: `{project}-eks-cluster-{environment}`
- **Trust Principal**: `eks.amazonaws.com`
- **Attached Policies**: AmazonEKSClusterPolicy
- **Purpose**: Allows EKS control plane to manage networking, load balancers, and cluster resources

### EKS Node Role
- **Name Pattern**: `{project}-eks-node-{environment}`
- **Trust Principal**: `ec2.amazonaws.com`
- **Attached Policies**: 
  - AmazonEKSWorkerNodePolicy
  - AmazonEKS_CNI_Policy
  - AmazonEC2ContainerRegistryPowerUser
  - AmazonSSMManagedInstanceCore
  - CloudWatchAgentServerPolicy
- **Purpose**: Allows EC2 nodes to pull images, join cluster, and publish metrics

## Key Variables

- `project_name` - Project name (default: "dpn")
- `environment` - Environment name (default: "part")
- `tags` - Additional tags for resources

## Outputs

- `kms_key_id` - KMS key ID
- `kms_key_arn` - KMS key ARN (used by other modules)
- `kms_key_alias` - KMS key alias
- `eks_cluster_role_arn` - EKS cluster IAM role ARN
- `eks_node_role_arn` - EKS node IAM role ARN
- `eks_node_instance_profile` - Instance profile for EC2 nodes

## Dependencies

- None - This module has no module dependencies

## Security Best Practices

✅ **Implemented:**
- Key Rotation - Automatic yearly rotation
- Least Privilege - Each role has only necessary permissions
- Deletion Protection - 30-day window prevents accidental key deletion
- Audit Trail - All key usage logged to CloudTrail

## Related Modules

- **Networking** - Uses KMS key for VPC Flow Logs
- **Database** - Uses KMS key for RDS encryption
- **EKS** - Uses IAM roles and KMS key
- **Observability** - Uses KMS key for CloudWatch Logs

## References

- [AWS KMS Documentation](https://docs.aws.amazon.com/kms/)
- [EKS IAM Roles](https://docs.aws.amazon.com/eks/latest/userguide/security_iam_service-with-iam.html)
