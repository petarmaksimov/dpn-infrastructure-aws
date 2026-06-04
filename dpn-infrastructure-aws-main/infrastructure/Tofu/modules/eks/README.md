# EKS Module

## Overview

The EKS module provisions an Amazon Elastic Kubernetes Service cluster with:
- **Private API Endpoint** - Control plane only accessible from private VPC
- **Managed Node Groups** - Auto-managed EC2 instances running Kubernetes
- **System & App Node Groups** - Separate node groups for system and application workloads
- **KMS Encryption** - Secrets encrypted with customer-managed key
- **Control Plane Logging** - API, audit, and other logs to CloudWatch
- **IRSA Enabled** - IAM roles for service accounts

## Key Features

- **Kubernetes Version**: 1.33+ (configurable)
- **API Endpoint**: Private access only (restricted to VPC)
- **Encryption**: KMS key for etcd secrets
- **Logging**: Control plane logs to CloudWatch
- **Node Groups**: System and app node groups
- **OIDC Provider**: Enabled for IRSA
- **Auto-scaling**: Cluster autoscaler enabled

## Resources Created

### EKS Cluster
- **Name**: `{project}-{environment}` (e.g., dpn-part)
- **API Endpoint**: Private only
- **Encryption**: KMS for Kubernetes secrets
- **Logging**: Control plane logs
- **OIDC Provider**: For service account IAM roles

### System Node Group
- **Name**: `ng-{project}-{environment}-system`
- **Instance Type**: t3.medium (2 vCPU, 1 GB RAM)
- **Desired Size**: 2 nodes
- **Range**: 1-3 nodes
- **Taints**: system=true

### App Node Group (Optional)
- **Configurable instance types**
- **Auto-scaling enabled**
- **Spot instance support**

## Key Variables

- `cluster_name` - EKS cluster name
- `kubernetes_version` - K8s version (default: "1.33")
- `endpoint_private_access` - Private endpoint (default: true)
- `endpoint_public_access` - Public endpoint (default: false)
- `cluster_log_types` - CloudWatch log types
- `cluster_role_arn` - EKS cluster IAM role
- `node_role_arn` - Node IAM role
- `private_subnet_ids` - Subnets for node deployment
- `kms_key_arn` - KMS key for encryption

## Outputs

- `cluster_id` - EKS cluster ID
- `cluster_arn` - EKS cluster ARN
- `cluster_endpoint` - API endpoint
- `cluster_version` - Kubernetes version
- `cluster_security_group_id` - Security group
- `oidc_provider_arn` - OIDC provider ARN (for IRSA)

## Usage Examples

### Get Cluster Info

```bash
# Get kubeconfig
aws eks update-kubeconfig --name dpn-part --region eu-west-2

# Verify connection
kubectl cluster-info
kubectl get nodes
```

### Scale Node Group

```bash
aws eks update-nodegroup-config \
  --cluster-name dpn-part \
  --nodegroup-name ng-dpn-part-app \
  --scaling-config minSize=1,maxSize=5,desiredSize=3
```

### View Control Plane Logs

```bash
# View API logs
aws logs tail /aws/eks/dpn-part/api --follow

# Query with Logs Insights
aws logs start-query \
  --log-group-name /aws/eks/dpn-part/api \
  --start-time $(date -d '1 hour ago' +%s) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp, verb, user | filter verb = "create"'
```

### Node Metrics

```bash
# Get node metrics
kubectl top nodes
kubectl top pods --all-namespaces

# Describe node
kubectl describe node {node-name}
```

## Security Best Practices

✅ **Implemented:**
- Private API endpoint only
- KMS encryption for secrets
- Security group controls
- IAM roles for service accounts (IRSA)
- Control plane logging

## Cost Optimization

- **System Node**: ~$0.0416/hour per t3.medium
- **Spot Instances**: Up to 90% discount
- **Reserved Instances**: 40-50% discount

### Optimize Costs
1. Use spot instances for non-critical workloads
2. Right-size nodes
3. Use Karpenter for advanced scheduling
4. Reserved Instances for predictable workloads

## Troubleshooting

### Nodes Not Joining Cluster

```bash
# Check node status
kubectl get nodes -o wide

# Describe node for events
kubectl describe node {node-name}

# Check node logs
aws ssm start-session --target {instance-id}
tail -f /var/log/cloud-init-output.log
```

### Pod Pending / Not Scheduling

```bash
# Check pod status
kubectl describe pod {pod-name} -n {namespace}

# Check node taints
kubectl describe node {node-name} | grep Taints
```

### API Endpoint Not Accessible

```bash
# Verify endpoint is accessible
kubectl cluster-info

# Check security group rules
aws ec2 describe-security-groups --group-ids sg-xxxxx
```

## Monitoring

### CloudWatch Metrics
- `cluster/node_count` - Number of nodes
- `cluster/pending_pods` - Pods waiting for resources
- `pods/cpu_utilization` - CPU usage
- `pods/memory_utilization` - Memory usage

### Node Metrics

```bash
kubectl get nodes --no-headers | wc -l  # Total nodes
kubectl top nodes --no-headers | awk '{sum+=$2} END {print sum " millicores"}'  # Total CPU
```

## Dependencies

- **Security Module** - Provides IAM roles and KMS key
- **Networking Module** - Provides VPC, subnets, security groups
- **Observability Module** - For logging

## Related Modules

- **Container Registry** - Stores images for deployment
- **Workload Identity** - Enables IRSA
- **Ingress** - ALB integration

## References

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
