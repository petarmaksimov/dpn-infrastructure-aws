# Ingress Module

## Overview

The ingress module provisions secure public ingress infrastructure for the deployment:
- **Application Load Balancer (ALB)** - Layer 7 routing and SSL termination
- **AWS WAF** - Web Application Firewall with custom rules
- **ACM Certificates** - HTTPS encryption
- **Route53** - DNS routing and health checks
- **Custom WAF Rules** - HTTP method enforcement, malicious user-agent blocking

## Key Features

- **ALB Type**: Application Load Balancer (Layer 7)
- **Listeners**: HTTPS (443), HTTP (80 redirect)
- **HTTPS Certificate**: ACM with DNS validation
- **WAF**: v2 with managed rules + 2 custom rules
- **Custom Rule 1**: HTTP method enforcement
- **Custom Rule 2**: Malicious user-agent blocking
- **Logging**: ALB access logs to S3, WAF logs to CloudWatch
- **Health Checks**: 30-second interval with configurable path

## Resources Created

### Application Load Balancer
- **Name**: `alb-{project}-{environment}`
- **Subnets**: Public subnets (for internet access)
- **Listeners**:
  - HTTPS (443) with TLS 1.2+
  - HTTP (80) redirect to HTTPS
- **Target Group**: EKS ingress (port 80)
- **Access Logs**: S3 bucket with versioning

### AWS WAF v2

**Managed Rules:**
- AWS Managed Rules (OWASP Top 10)
- Bot Control (scrapers, etc.)
- Core Rule Set

**Custom Rules:**
1. HTTP Method Enforcement (block non-standard methods)
2. Malicious User-Agent Blocking (block scanners)
3. GeoIP Blocking (optional: KP, IR, SY)

### ACM Certificate
- **Domain**: Primary domain (configurable)
- **Alternates**: Wildcard domain
- **Validation**: DNS (automatic)
- **Auto-renewal**: 60 days before expiry

### Route53 Records
- **A Record**: Alias to ALB
- **Health Checks**: Monitor ALB availability

## Key Variables

- `project_name` - Project name (default: "dpn")
- `environment` - Environment name (default: "part")
- `domain_name` - Primary domain (e.g., "example.com")
- `certificate_arn` - ACM certificate ARN (or create new)
- `alb_target_port` - EKS ingress port (default: 80)
- `blocked_country_codes` - ISO country codes (default: ["KP", "IR", "SY"])
- `waf_allowed_http_methods` - Allowed methods (GET, POST, PUT, DELETE, etc.)
- `waf_blocked_user_agent_regexes` - Scanner patterns (sqlmap, nikto, nessus, etc.)
- `enable_waf_logging` - Log blocked requests (default: true)

## Outputs

- `alb_arn` - ALB ARN
- `alb_dns_name` - ALB DNS name
- `alb_zone_id` - Zone ID for Route53 alias
- `target_group_arn` - Target group ARN
- `waf_acl_arn` - WAF Web ACL ARN
- `certificate_arn` - ACM certificate ARN

## Usage Examples

### Test ALB

```bash
# Test direct to ALB
curl -k https://{alb-dns-name}/

# Test via domain
curl -k https://api.example.com/

# Check target health
aws elbv2 describe-target-health --target-group-arn {target-group-arn}
```

### View WAF Blocked Requests

```bash
aws logs start-query \
  --log-group-name "/aws/waf/dpn-part" \
  --query-string 'fields @timestamp, httpRequest.clientIp, action | filter action = "BLOCK"'
```

### Create DNS Record

```bash
# Get ALB details
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --names alb-dpn-part \
  --query 'LoadBalancers[0].DNSName' --output text)

ALB_ZONE=$(aws elbv2 describe-load-balancers \
  --names alb-dpn-part \
  --query 'LoadBalancers[0].CanonicalHostedZoneId' --output text)

# Create Route53 alias record
aws route53 change-resource-record-sets \
  --hosted-zone-id {zone-id} \
  --change-batch "..."
```

## WAF Rules

### Rule 1: HTTP Method Enforcement
- **Allowed**: GET, POST, PUT, DELETE, HEAD, OPTIONS, PATCH
- **Blocked**: TRACE, CONNECT, and other non-standard methods
- **Action**: Log and Block

### Rule 2: Malicious User-Agent Blocking
- **Pattern**: Blocks scanners (sqlmap, nikto, nessus, masscan, etc.)
- **Action**: Log and Block
- **Severity**: HIGH

### Rule 3: GeoIP Blocking (optional)
- **Countries**: KP, IR, SY (configurable)
- **Action**: Log and Block
- **Severity**: MEDIUM

## Security Best Practices

✅ **Implemented:**
- TLS 1.2+ only (HTTPS)
- WAF with managed rules
- Custom HTTP method enforcement
- Scanner detection (user-agent blocking)
- GeoIP blocking
- ALB access logs
- Health checks enabled

## Cost Optimization

- **ALB**: ~$16/month
- **LCU**: ~$4-6/month
- **WAF**: $5/month + $1/rule
- **Requests**: $0.60 per million

## Monitoring

### CloudWatch Metrics
- HTTPCode_Target_5XX_Count
- TargetResponseTime
- RequestCount

### ALB Access Logs
- Stored in S3 bucket
- 5-minute delivery
- Queryable with S3 Select

## Troubleshooting

### Cannot Access ALB

1. Check target group health: `aws elbv2 describe-target-health`
2. Verify security groups
3. Check WAF is not blocking (review logs)
4. Verify EKS ingress is running

### Certificate Issues

```bash
aws acm describe-certificate --certificate-arn {cert-arn}
```

## Dependencies

- **Security Module** - Provides KMS key
- **Networking Module** - Provides public subnets
- **Observability Module** - Provides logging
- **EKS Module** - Provides ingress targets

## References

- [Application Load Balancer Documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)
- [AWS WAF v2 Documentation](https://docs.aws.amazon.com/wafv2/)
- [ACM Certificate Management](https://docs.aws.amazon.com/acm/)
