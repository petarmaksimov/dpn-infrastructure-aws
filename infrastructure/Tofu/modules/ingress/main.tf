locals {
  fqdn = "${var.ingress_hostname}.${var.domain_name}"
}

resource "aws_wafv2_regex_pattern_set" "blocked_user_agents" {
  count = var.enable_waf && length(var.waf_blocked_user_agent_regexes) > 0 ? 1 : 0

  name  = "waf-bad-ua-${var.project_name}-${var.environment}"
  scope = "REGIONAL"

  dynamic "regular_expression" {
    for_each = var.waf_blocked_user_agent_regexes

    content {
      regex_string = regular_expression.value
    }
  }

  tags = var.tags
}

resource "aws_lb" "this" {
  name               = "alb-${var.project_name}-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  dynamic "access_logs" {
    for_each = var.alb_logs_bucket_name != null && var.alb_logs_bucket_name != "" ? [1] : []

    content {
      enabled = true
      bucket  = var.alb_logs_bucket_name
      prefix  = "alb"
    }
  }

  enable_deletion_protection = false

  tags = var.tags
}

resource "aws_lb_target_group" "ingress" {
  name        = "tg-${var.project_name}-${var.environment}"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    path                = "/healthz"
    matcher             = "200-399"
  }

  tags = var.tags
}

resource "aws_acm_certificate" "this" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [local.fqdn]

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

resource "aws_route53_record" "validation" {
  for_each = var.route53_zone_id != "REPLACE_WITH_DEV_ROUTE53_ZONE_ID" ? {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  zone_id = var.route53_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.this.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ingress.arn
  }
}

resource "aws_route53_record" "ingress_alias" {
  zone_id = var.route53_zone_id
  name    = local.fqdn
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}

resource "aws_wafv2_web_acl" "this" {
  count = var.enable_waf ? 1 : 0

  name  = "waf-${var.project_name}-${var.environment}"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "waf-${var.project_name}-${var.environment}"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "managed-common"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "managed-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "managed-ip-reputation"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesAnonymousIpList"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "managed-anon-ip"
      sampled_requests_enabled   = true
    }
  }

  dynamic "rule" {
    for_each = length(var.waf_allowed_http_methods) > 0 ? [1] : []

    content {
      name     = "BlockDisallowedHttpMethods"
      priority = 5

      action {
        block {}
      }

      statement {
        not_statement {
          statement {
            or_statement {
              dynamic "statement" {
                for_each = var.waf_allowed_http_methods

                content {
                  byte_match_statement {
                    field_to_match {
                      method {}
                    }

                    positional_constraint = "EXACTLY"
                    search_string         = statement.value

                    text_transformation {
                      priority = 0
                      type     = "NONE"
                    }
                  }
                }
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "block-disallowed-http-methods"
        sampled_requests_enabled   = true
      }
    }
  }

  dynamic "rule" {
    for_each = length(var.waf_blocked_user_agent_regexes) > 0 ? [1] : []

    content {
      name     = "BlockMaliciousUserAgents"
      priority = 6

      action {
        block {}
      }

      statement {
        regex_pattern_set_reference_statement {
          arn = aws_wafv2_regex_pattern_set.blocked_user_agents[0].arn

          field_to_match {
            single_header {
              name = "user-agent"
            }
          }

          text_transformation {
            priority = 0
            type     = "NONE"
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "block-malicious-user-agents"
        sampled_requests_enabled   = true
      }
    }
  }

  rule {
    name     = "RateLimitPerIP"
    priority = 10

    action {
      block {}
    }

    statement {
      rate_based_statement {
        aggregate_key_type = "IP"
        limit              = var.waf_rate_limit
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate-limit"
      sampled_requests_enabled   = true
    }
  }

  dynamic "rule" {
    for_each = length(var.blocked_country_codes) > 0 ? [1] : []

    content {
      name     = "GeoRestrictionBlock"
      priority = 9

      action {
        block {}
      }

      statement {
        geo_match_statement {
          country_codes = var.blocked_country_codes
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "geo-restriction"
        sampled_requests_enabled   = true
      }
    }
  }

  tags = var.tags
}

resource "aws_wafv2_web_acl_association" "this" {
  count = var.enable_waf ? 1 : 0

  resource_arn = aws_lb.this.arn
  web_acl_arn  = aws_wafv2_web_acl.this[0].arn
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  count = var.enable_waf && var.enable_waf_logging ? 1 : 0

  resource_arn            = aws_wafv2_web_acl.this[0].arn
  log_destination_configs = [var.waf_log_group_arn]
}
