output "alb_arn" {
  value = aws_lb.this.arn
}

output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "alb_zone_id" {
  value = aws_lb.this.zone_id
}

output "waf_web_acl_arn" {
  value = var.enable_waf ? aws_wafv2_web_acl.this[0].arn : null
}

output "ingress_fqdn" {
  value = aws_route53_record.ingress_alias.fqdn
}
