# Observability Module

## Overview

The observability module establishes comprehensive logging and monitoring infrastructure for all AWS services:
- **CloudWatch Log Groups** - Centralized logging for VPC, Network Firewall, EKS, SSM, ALB, and WAF
- **S3 Buckets** - Long-term log storage for ALB, Network Firewall, and SSM logs
- **Log Retention Policies** - Automated log lifecycle management
- **KMS Encryption** - All logs encrypted at rest

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│              Observability Module                        │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  CloudWatch Log Groups                                  │
│  ├─ /aws/vpc/flow/{project}-{environment}              │
│  ├─ /aws/network-firewall/flow/{project}-{env}        │
│  ├─ /aws/network-firewall/alert/{project}-{env}       │
│  ├─ /aws/eks/control-plane/{project}-{env}            │
│  ├─ /aws/ssm/sessions/{project}-{env}                 │
│  ├─ /aws/waf/{project}-{env}                           │
│  └─ /aws/alb/{project}-{env}                           │
│                                                          │
│  S3 Buckets (Long-term Storage)                         │
│  ├─ {project}-alb-logs-{env}-{account-id}             │
│  ├─ {project}-nfw-logs-{env}-{account-id}             │
│  └─ {project}-ssm-logs-{env}-{account-id}             │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

## Resources Created

### CloudWatch Log Groups

| Log Group | Source | Retention | Purpose |
|-----------|--------|-----------|---------|
| `/aws/vpc/flow/*` | VPC Flow Logs | 30 days | Network traffic monitoring |
| `/aws/network-firewall/flow/*` | Network Firewall | 30 days | Firewall flow events |
| `/aws/network-firewall/alert/*` | Network Firewall | 30 days | Security alerts |
| `/aws/eks/control-plane/*` | EKS API | 30 days | Kubernetes control plane |
| `/aws/ssm/sessions/*` | Session Manager | 30 days | Session transcripts |
| `/aws/waf/*` | Web ACL | 30 days | WAF decisions |
| `/aws/alb/*` | ALB | 30 days | Load balancer access |

### S3 Buckets for Log Storage

- **ALB Logs Bucket** - Access logs with lifecycle rules
- **Network Firewall Logs Bucket** - Flow and alert logs
- **SSM Logs Bucket** - Session manager logs and transcripts

All buckets have:
- ✅ Versioning enabled
- ✅ KMS encryption
- ✅ Public access blocked
- ✅ Lifecycle policies
- ✅ Server-side encryption

## Key Variables

- `project_name` - Project name (default: "dpn")
- `environment` - Environment name (default: "part")
- `log_retention_in_days` - CloudWatch log retention (default: 30)
- `kms_key_arn` - KMS key ARN for encryption
- `enable_alb_logging` - Enable ALB logs (default: true)
- `enable_firewall_logging` - Enable Firewall logs (default: true)
- `enable_ssm_logging` - Enable SSM logs (default: true)
- `enable_eks_control_plane_logging` - Enable EKS logs (default: true)
- `vpc_flow_log_traffic_type` - ALL, ACCEPT, or REJECT (default: ALL)

## Outputs

- `vpc_flow_log_group_name` - CloudWatch log group for VPC flow logs
- `vpc_flow_log_group_arn` - ARN of VPC flow log group
- `firewall_flow_log_group_name` - Network Firewall flow logs group
- `firewall_alert_log_group_name` - Network Firewall alert logs group
- `eks_control_plane_log_group_name` - EKS control plane logs group
- `ssm_session_log_group_name` - SSM session logs group
- `waf_log_group_name` - WAF logs group
- `alb_log_group_name` - ALB logs group
- `alb_logs_bucket` - S3 bucket for ALB logs
- `firewall_logs_bucket` - S3 bucket for firewall logs
- `ssm_logs_bucket` - S3 bucket for SSM logs

## Dependencies

- **Security Module** - Provides `kms_key_arn` for encryption
- **AWS Account** - CloudWatch and S3 permissions

## Usage Examples

### Query VPC Flow Logs for Rejected Traffic

```bash
aws logs start-query \
  --log-group-name "/aws/vpc/flow/dpn-part" \
  --start-time $(date -d '1 hour ago' +%s) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp, srcaddr, dstaddr, action | filter action = "REJECT"'
```

### Query EKS Control Plane for Errors

```bash
aws logs start-query \
  --log-group-name "/aws/eks/control-plane/dpn-part" \
  --start-time $(date -d '1 hour ago' +%s) \
  --end-time $(date +%s) \
  --query-string 'fields @message | filter @message like /ERROR/'
```

### Increase Log Retention for Production

```hcl
log_retention_in_days = 90  # Store logs for 90 days instead of 30
```

## Cost Optimization

- **CloudWatch Logs**: $0.50/GB ingestion, $0.03/GB-month storage
- **Adjust retention**: Reduce retention for non-critical logs
- **Archive to S3**: Move old logs to Glacier for long-term storage
- **Use sampling**: Don't log every request

## Security Best Practices

✅ **Implemented:**
- Encryption at Rest - KMS encryption
- Access Control - Private S3 buckets
- Immutability - Versioning enabled
- Retention Policies - Automatic cleanup
- Audit Trail - CloudTrail logging

## Related Modules

- **Security** - Provides KMS key for encryption
- **Networking** - Generates VPC Flow Logs
- **EKS** - Generates control plane logs
- **Ingress** - ALB generates access logs
- **Compliance** - Uses CloudWatch for audit logs

## References

- [CloudWatch Logs Documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/)
- [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)
- [CloudWatch Logs Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax.html)
