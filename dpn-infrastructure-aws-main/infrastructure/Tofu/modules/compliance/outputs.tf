output "guardduty_detector_id" {
  value = try(aws_guardduty_detector.this[0].id, null)
}

output "security_hub_enabled" {
  value = var.enable_security_hub
}

output "cloudtrail_name" {
  value = try(aws_cloudtrail.this[0].name, null)
}

output "cloudtrail_bucket_name" {
  value = try(aws_s3_bucket.cloudtrail[0].bucket, null)
}

output "config_bucket_name" {
  value = try(aws_s3_bucket.config[0].bucket, null)
}

output "session_manager_preferences_document_name" {
  value = try(aws_ssm_document.session_manager_preferences[0].name, null)
}
