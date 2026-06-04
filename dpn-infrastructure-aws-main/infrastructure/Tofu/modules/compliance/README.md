# Compliance Module

## Overview

The compliance module establishes governance, compliance, and security audit infrastructure:
- **AWS GuardDuty** - Intelligent threat detection
- **AWS Security Hub** - Centralized security findings aggregation
- **AWS CloudTrail** - Audit logging of all AWS API calls
- **AWS Config** - Configuration compliance tracking
- **Session Manager Preferences** - Audit and control for SSM sessions

## Key Features

- **GuardDuty**: Threat detection enabled by default
- **Security Hub**: Findings aggregation (AWS standards)
- **CloudTrail**: Multi-region audit trail with 90-day retention
- **AWS Config**: 7 compliance rules enabled
- **Session Manager**: Audit logging + timeout controls
- **Encryption**: All logs encrypted with KMS

## Resources Created

### GuardDuty
- **Detector**: Enabled for threat detection
- **Analysis**: Network, DNS, VPC flow logs
- **Retention**: 90 days
- **Notifications**: CloudWatch Logs + optional SNS

### Security Hub
- **Account**: Enabled for findings aggregation
- **Standards**: AWS Foundational Security Best Practices
- **Integrations**: GuardDuty, Config, IAM Access Analyzer

### CloudTrail
- **Trail**: Multi-region enabled
- **S3 Bucket**: Versioning + lifecycle policies
- **CloudWatch Logs**: Real-time log streaming
- **Encryption**: KMS key
- **Retention**: 90 days in S3

### AWS Config
- **Recorder**: Enabled for all resources
- **Delivery Channel**: S3 + CloudWatch Logs
- **7 Rules**:
  1. `ec2-imdsv2-check` - Enforce IMDSv2 (secure metadata)
  2. `eks-endpoint-public-access` - Verify EKS private endpoints
  3. `ec2-instance-managed-by-systems-manager` - SSM agent present
  4. `rds-instance-public-access-check` - RDS not publicly accessible
  5. `s3-bucket-public-read-prohibited` - S3 no public read
  6. `s3-bucket-public-write-prohibited` - S3 no public write
  7. `kms-key-rotation-enabled` - KMS keys have rotation

### Session Manager Document
- **Name**: `{project}-session-manager-{environment}`
- **CloudWatch Logging**: Enabled
- **S3 Logging**: Session transcripts
- **Session Timeout**: 60 minutes
- **Idle Timeout**: 20 minutes
- **Run-as User**: ec2-user (restricted)

## Key Variables

- `project_name` - Project name (default: "dpn")
- `environment` - Environment name (default: "part")
- `enable_guardduty` - Enable threat detection (default: true)
- `enable_security_hub` - Enable findings (default: true)
- `enable_cloudtrail` - Enable audit logs (default: true)
- `enable_aws_config` - Enable compliance rules (default: true)
- `enable_session_manager_preferences` - Enable SSM audit (default: true)
- `cloudtrail_retention_days` - CloudTrail S3 retention (default: 90)
- `kms_key_arn` - KMS key for encryption

## Outputs

- `guardduty_detector_id` - GuardDuty detector ID
- `guardduty_detector_arn` - GuardDuty detector ARN
- `security_hub_arn` - Security Hub ARN
- `cloudtrail_arn` - CloudTrail ARN
- `config_recorder_id` - Config recorder ID
- `config_delivery_channel_name` - Config delivery channel name

## Usage Examples

### View GuardDuty Findings

```bash
aws guardduty list-findings --detector-id {detector-id}

aws guardduty get-findings \
  --detector-id {detector-id} \
  --finding-ids {finding-id}
```

### Check Security Hub Insights

```bash
aws securityhub get-insights

aws securityhub get-insight-results --insight-arn {insight-arn}
```

### Query CloudTrail Logs

```bash
aws cloudtrail lookup-events --max-results 10

aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=Username,AttributeValue=admin
```

### View Config Compliance

```bash
aws configservice describe-compliance-by-config-rule

aws configservice get-compliance-details-by-config-rule \
  --config-rule-name ec2-imdsv2-check
```

### Check Session Manager Logs

```bash
aws logs tail /aws/ssm/sessions --follow

aws s3 ls s3://{ssm-logs-bucket}/transcripts/
```

## Config Rules Details

| Rule | Purpose | Action |
|------|---------|--------|
| IMDSv2 | Enforce secure metadata | Auto-tag |
| EKS Private | Verify private endpoints | Alert |
| SSM Agent | Verify EC2 has agent | Alert |
| RDS Private | Ensure RDS not public | Alert |
| S3 No Read | Prevent public read | Auto-deny |
| S3 No Write | Prevent public write | Auto-deny |
| KMS Rotation | Verify key rotation | Alert |

## Security Best Practices

✅ **Implemented:**
- GuardDuty threat detection enabled
- Security Hub centralized findings
- CloudTrail encrypted audit logs
- 7 AWS Config compliance rules
- Session Manager audit logging
- KMS encryption for all logs
- Automatic compliance checks

## Cost Optimization

- **GuardDuty**: ~$3/month
- **Security Hub**: $0.001/finding (100 free)
- **CloudTrail**: $2 + $0.10/100k events
- **Config**: $3-4/month

## Monitoring & Alerts

### CloudWatch Alarms

```bash
# Alert on threats
aws cloudwatch put-metric-alarm \
  --alarm-name guardduty-findings \
  --metric-name FindingsCount \
  --namespace AWS/GuardDuty \
  --threshold 1
```

### Security Hub Dashboard

Access unified view of:
- GuardDuty findings
- Config rule compliance
- CloudTrail events
- IAM findings

## Troubleshooting

### GuardDuty Not Detecting Threats

1. Verify detector is enabled
2. Check network/DNS analysis enabled
3. Ensure CloudTrail logs present

### CloudTrail Not Logging

1. Check trail is started
2. Verify S3 bucket policy
3. Check IAM permissions

### Config Rules Not Running

1. Verify recorder is started
2. Check delivery channel active
3. Review rule scope

## Dependencies

- **Security Module** - Provides KMS key
- **Observability Module** - Provides log groups and buckets

## References

- [GuardDuty Documentation](https://docs.aws.amazon.com/guardduty/)
- [Security Hub Documentation](https://docs.aws.amazon.com/securityhub/)
- [CloudTrail Documentation](https://docs.aws.amazon.com/cloudtrail/)
- [AWS Config Documentation](https://docs.aws.amazon.com/config/)

## Main resources created
- `aws_ssm_document.session_manager_preferences` (optional)
- `aws_guardduty_detector.this` (optional)
- `aws_securityhub_account.this` (optional)
- `aws_cloudtrail.this` + encrypted CloudTrail S3 bucket/policy (optional)
- AWS Config infrastructure (optional):
  - `aws_config_configuration_recorder`
  - `aws_config_delivery_channel`
  - `aws_config_configuration_recorder_status`
  - AWS Config S3 bucket/policy and IAM role
- AWS Config managed rules implemented in code:
  - `ec2-imdsv2-check`
  - `eks-endpoint-no-public-access`
  - `restricted-ssh`
  - `rds-instance-public-access-check`
  - `s3-bucket-public-read-prohibited`
  - `kms-cmk-backing-key-rotation-enabled`
  - `cloud-trail-enabled`

## How it is configured
Key inputs:
- `project_name`, `environment`, `aws_region`
- `kms_key_arn` for encryption
- Feature toggles:
  - `enable_guardduty`
  - `enable_security_hub`
  - `enable_cloudtrail`
  - `enable_aws_config`
  - `enable_session_manager_preferences`
- Session Manager settings:
  - `ssm_sessions_log_group_name`
  - `ssm_logs_bucket_name`
  - `ssm_idle_session_timeout_minutes`
  - `ssm_max_session_duration_minutes`
  - `ssm_run_as_default_user`

## Outputs
- `guardduty_detector_id`
- `security_hub_enabled`
- `cloudtrail_name`
- `cloudtrail_bucket_name`
- `config_bucket_name`
- `session_manager_preferences_document_name`

## Operational notes
- Session Manager preferences document is created only when logging destinations are provided.
- CloudTrail and Config buckets are encrypted with your provided KMS key and have public access blocked.
- Most controls are optional and gated by booleans, which allows phased rollout by environment.
