output "vpc_flow_log_group_name" {
  value = aws_cloudwatch_log_group.vpc_flow.name
}

output "vpc_flow_log_group_arn" {
  value = aws_cloudwatch_log_group.vpc_flow.arn
}

output "firewall_flow_log_group_arn" {
  value = aws_cloudwatch_log_group.firewall_flow.arn
}

output "firewall_alert_log_group_arn" {
  value = aws_cloudwatch_log_group.firewall_alert.arn
}

output "eks_control_plane_log_group_name" {
  value = aws_cloudwatch_log_group.eks_control_plane.name
}

output "ssm_sessions_log_group_name" {
  value = aws_cloudwatch_log_group.ssm_sessions.name
}

output "alb_logs_bucket_name" {
  value = var.create_log_s3_buckets ? aws_s3_bucket.alb_logs[0].bucket : null
}

output "firewall_logs_bucket_name" {
  value = var.create_log_s3_buckets ? aws_s3_bucket.firewall_logs[0].bucket : null
}

output "ssm_logs_bucket_name" {
  value = var.create_log_s3_buckets ? aws_s3_bucket.ssm_logs[0].bucket : null
}

output "waf_log_group_arn" {
  value = aws_cloudwatch_log_group.waf.arn
}
