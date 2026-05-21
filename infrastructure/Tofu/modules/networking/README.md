# Networking Module

## Overview

The networking module establishes the foundational network infrastructure for the AWS deployment:
- **VPC** - Virtual Private Cloud with 10.120.0.0/16 CIDR block
- **Subnets** - 6 subnet tiers across 3 availability zones
- **Network Firewall** - Layer 7 security with stateful rules and logging
- **Transit Gateway** - Centralized routing and network segmentation
- **VPC Endpoints** - 9 interface endpoints + S3 gateway with scoped policies
- **NAT Gateways** - Outbound internet access from private subnets
- **VPC Flow Logs** - Network traffic monitoring

## Key Features

- **VPC CIDR**: 10.120.0.0/16 (4,096 IP addresses)
- **Subnet Tiers**: Public, App, Data, Firewall, Transit Gateway, Management
- **Availability Zones**: 3 AZs (a, b, c) for high availability
- **Network Firewall**: Layer 7 stateful inspection
- **VPC Endpoints**: 9 interface + 1 S3 gateway for private access
- **Transit Gateway**: Centralized hub-and-spoke routing
- **Flow Logs**: VPC flow logging to CloudWatch

## Subnets (18 total - 3 AZs × 6 tiers)

| Tier | CIDR | Purpose | Route |
|------|------|---------|-------|
| Public | 10.120.{1-3}.0/24 | ALB, NAT gateway | IGW |
| App | 10.120.{11-13}.0/24 | EKS nodes | NFW→NAT→IGW |
| Data | 10.120.{21-23}.0/24 | RDS, Redis | No IGW |
| Firewall | 10.120.{31-33}.0/24 | Network Firewall | IGW |
| Transit Gateway | 10.120.{41-43}.0/24 | TGW attachment | IGW |
| Management | 10.120.{51-53}.0/24 | Bastion/VPN | IGW |

## VPC Endpoints (9 Interface + S3 Gateway)

- EC2 - Launch/manage instances
- S3 - Access S3 buckets (gateway)
- ECR - Pull container images
- CloudWatch Logs - Push logs
- CloudTrail - Push audit logs
- Secrets Manager - Retrieve secrets
- KMS - Encryption operations
- SSM - Session Manager, parameters
- SNS - Send notifications

All endpoints have scoped IAM policies (least privilege).

## Key Variables

- `project_name` - Project name (default: "dpn")
- `environment` - Environment name (default: "part")
- `vpc_cidr` - VPC CIDR block (default: "10.120.0.0/16")
- `enable_network_firewall` - Enable Layer 7 firewall (default: true)
- `enable_vpc_endpoints` - Enable VPC endpoints (default: true)
- `enable_restrictive_endpoint_policies` - Apply scoped IAM policies (default: true)
- `enable_vpc_flow_logs` - Enable flow logs (default: true)

## Outputs

- `vpc_id` - VPC ID
- `vpc_cidr_block` - VPC CIDR
- `subnet_ids_public` - Public subnet IDs
- `subnet_ids_app` - App subnet IDs
- `subnet_ids_data` - Data subnet IDs
- `nat_gateway_ips` - NAT gateway public IPs
- `network_firewall_id` - Network Firewall ID
- `tgw_id` - Transit Gateway ID

## Usage Examples

### Launch EKS Nodes

```hcl
resource "aws_eks_node_group" "app" {
  subnet_ids = var.subnet_ids_app
}
```

### Launch RDS

```hcl
resource "aws_db_subnet_group" "this" {
  subnet_ids = var.subnet_ids_data
}
```

### Query VPC Flow Logs

```bash
aws logs start-query \
  --log-group-name "/aws/vpc/flow/dpn-part" \
  --query-string 'fields @timestamp, srcaddr, dstaddr, action | filter action = "REJECT"'
```

## Routing Architecture

```
Internet → IGW → NFW (inspect) → NAT → App Subnets (EKS)
                                        ↓
                                  Transit Gateway (hub)
```

## Traffic Flow

- **Egress**: App → TGW → NFW → NAT → IGW → Internet
- **Ingress**: Internet → IGW → ALB → App Subnets
- **Private**: App ↔ Data (no internet)

## Security Best Practices

✅ **Implemented:**
- VPC endpoints (avoid internet exposure)
- Network Firewall (Layer 7 protection)
- Restrictive endpoint policies
- Flow logs for monitoring
- Private data subnet (no IGW)
- Transit Gateway for segmentation

## Cost Optimization

- **VPC Endpoints**: $7/month × 9 interface endpoints
- **Network Firewall**: ~$120/month + processing charges
- **NAT Gateways**: ~$32/month × 3 gateways
- **Transit Gateway**: ~$36/month + processing

## Dependencies

- **Security Module** - Provides KMS key for log encryption

## References

- [VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Network Firewall](https://docs.aws.amazon.com/wafv2/latest/developerguide/waf-chapter-network-firewall.html)
- [VPC Endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/)
- [Transit Gateway](https://docs.aws.amazon.com/vpc/latest/tgw/)
- Security groups for ALB, EKS nodes, data tier, and management tier
