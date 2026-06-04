locals {
  name_prefix = "${var.project_name}-${var.environment}"
  az_map      = { for idx, az in var.azs : az => idx }

  firewall_logging_configs = {
    for k, v in {
      FLOW  = var.firewall_flow_log_group_arn
      ALERT = var.firewall_alert_log_group_arn
    } : k => v if v != null && v != ""
  }

  interface_endpoint_services = {
    ecr_api        = "ecr.api"
    ecr_dkr        = "ecr.dkr"
    secretsmanager = "secretsmanager"
    sts            = "sts"
    logs           = "logs"
    ssm            = "ssm"
    ssmmessages    = "ssmmessages"
    ec2messages    = "ec2messages"
    eks            = "eks"
  }

  interface_endpoint_policies = {
    ecr_api = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid       = "AllowEcrApiReadPull"
          Effect    = "Allow"
          Principal = "*"
          Action = [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:DescribeRepositories"
          ]
          Resource = "*"
        }
      ]
    })
    ecr_dkr = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid       = "AllowEcrDockerPull"
          Effect    = "Allow"
          Principal = "*"
          Action = [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage"
          ]
          Resource = "*"
        }
      ]
    })
    secretsmanager = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid       = "AllowReadScopedSecrets"
          Effect    = "Allow"
          Principal = "*"
          Action = [
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret"
          ]
          Resource = [
            "arn:aws:secretsmanager:${var.aws_region}:*:secret:${var.project_name}/${var.environment}/*",
            "arn:aws:secretsmanager:${var.aws_region}:*:secret:${var.project_name}-${var.environment}*"
          ]
        }
      ]
    })
    sts = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid       = "AllowStsForIrsa"
          Effect    = "Allow"
          Principal = "*"
          Action = [
            "sts:AssumeRoleWithWebIdentity",
            "sts:GetCallerIdentity"
          ]
          Resource = "*"
        }
      ]
    })
    logs = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid       = "AllowCloudWatchLogsWrite"
          Effect    = "Allow"
          Principal = "*"
          Action = [
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogStreams",
            "logs:DescribeLogGroups"
          ]
          Resource = "*"
        }
      ]
    })
    ssm = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid       = "AllowSsmAgentCore"
          Effect    = "Allow"
          Principal = "*"
          Action = [
            "ssm:UpdateInstanceInformation",
            "ssm:ListInstanceAssociations",
            "ssm:DescribeAssociation",
            "ssm:GetDocument",
            "ssm:PutInventory",
            "ssm:PutComplianceItems",
            "ssm:PutConfigurePackageResult"
          ]
          Resource = "*"
        }
      ]
    })
    ssmmessages = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid       = "AllowSsmMessagesChannels"
          Effect    = "Allow"
          Principal = "*"
          Action = [
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel"
          ]
          Resource = "*"
        }
      ]
    })
    ec2messages = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid       = "AllowEc2MessagesChannels"
          Effect    = "Allow"
          Principal = "*"
          Action = [
            "ec2messages:AcknowledgeMessage",
            "ec2messages:DeleteMessage",
            "ec2messages:FailMessage",
            "ec2messages:GetEndpoint",
            "ec2messages:GetMessages",
            "ec2messages:SendReply"
          ]
          Resource = "*"
        }
      ]
    })
    eks = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid       = "AllowEksDescribe"
          Effect    = "Allow"
          Principal = "*"
          Action = [
            "eks:DescribeCluster",
            "eks:ListClusters"
          ]
          Resource = "*"
        }
      ]
    })
  }

  s3_gateway_endpoint_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3ListAndObjectIOOnly"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::*",
          "arn:aws:s3:::*/*"
        ]
      }
    ]
  })
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "vpc-${local.name_prefix}-${var.aws_region}"
  })
}

resource "aws_iam_role" "vpc_flow_logs" {
  count = var.vpc_flow_log_group_arn != null && var.vpc_flow_log_group_arn != "" ? 1 : 0

  name = "iam-${var.project_name}-vpc-flow-logs-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  count = var.vpc_flow_log_group_arn != null && var.vpc_flow_log_group_arn != "" ? 1 : 0

  name = "policy-${var.project_name}-vpc-flow-logs-${var.environment}"
  role = aws_iam_role.vpc_flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "${var.vpc_flow_log_group_arn}:*"
      }
    ]
  })
}

resource "aws_flow_log" "vpc" {
  count = var.vpc_flow_log_group_arn != null && var.vpc_flow_log_group_arn != "" ? 1 : 0

  log_destination      = var.vpc_flow_log_group_arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.this.id
  iam_role_arn         = aws_iam_role.vpc_flow_logs[0].arn

  tags = merge(var.tags, {
    Name = "fl-${var.project_name}-vpc-${var.environment}"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "igw-${local.name_prefix}-${var.aws_region}"
  })
}

resource "aws_subnet" "public" {
  for_each = local.az_map

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = var.subnet_cidrs.public[each.value]
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "sn-${var.project_name}-public-${replace(each.key, var.aws_region, "")}-${var.environment}"
    Tier = "public"
  })
}

resource "aws_subnet" "app" {
  for_each = local.az_map

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = var.subnet_cidrs.app[each.value]

  tags = merge(var.tags, {
    Name = "sn-${var.project_name}-app-${replace(each.key, var.aws_region, "")}-${var.environment}"
    Tier = "application"
  })
}

resource "aws_subnet" "data" {
  for_each = local.az_map

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = var.subnet_cidrs.data[each.value]

  tags = merge(var.tags, {
    Name = "sn-${var.project_name}-data-${replace(each.key, var.aws_region, "")}-${var.environment}"
    Tier = "data"
  })
}

resource "aws_subnet" "fw" {
  for_each = local.az_map

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = var.subnet_cidrs.fw[each.value]

  tags = merge(var.tags, {
    Name = "sn-${var.project_name}-fw-${replace(each.key, var.aws_region, "")}-${var.environment}"
    Tier = "firewall"
  })
}

resource "aws_subnet" "tgw" {
  for_each = local.az_map

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = var.subnet_cidrs.tgw[each.value]

  tags = merge(var.tags, {
    Name = "sn-${var.project_name}-tgw-${replace(each.key, var.aws_region, "")}-${var.environment}"
    Tier = "tgw"
  })
}

resource "aws_subnet" "mgmt" {
  for_each = local.az_map

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = var.subnet_cidrs.mgmt[each.value]

  tags = merge(var.tags, {
    Name = "sn-${var.project_name}-mgmt-${replace(each.key, var.aws_region, "")}-${var.environment}"
    Tier = "management"
  })
}

resource "aws_eip" "nat" {
  for_each = local.az_map

  domain = "vpc"

  tags = merge(var.tags, {
    Name = "eip-${var.project_name}-nat-${replace(each.key, var.aws_region, "")}-${var.environment}"
  })
}

resource "aws_nat_gateway" "this" {
  for_each = local.az_map

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = merge(var.tags, {
    Name = "nat-${var.project_name}-${replace(each.key, var.aws_region, "")}-${var.environment}"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_ec2_transit_gateway" "this" {
  description                     = "Transit gateway for ${local.name_prefix}"
  auto_accept_shared_attachments  = "disable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"

  tags = merge(var.tags, {
    Name = "tgw-${local.name_prefix}-${var.aws_region}"
  })
}

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  subnet_ids         = [for az in var.azs : aws_subnet.tgw[az].id]
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id             = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "tgw-attach-${local.name_prefix}-${var.aws_region}"
  })
}

resource "aws_networkfirewall_rule_group" "stateful_allowlist" {
  capacity = 100
  name     = "nfw-rg-stateful-${local.name_prefix}"
  type     = "STATEFUL"

  rule_group {
    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types         = ["HTTP_HOST", "TLS_SNI"]
        targets              = var.allowed_egress_fqdns
      }
    }
  }

  tags = var.tags
}

resource "aws_networkfirewall_rule_group" "stateless_baseline" {
  capacity = 100
  name     = "nfw-rg-stateless-${local.name_prefix}"
  type     = "STATELESS"

  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {
        stateless_rule {
          priority = 10

          rule_definition {
            actions = ["aws:pass"]

            match_attributes {
              protocols = [6]

              destination_port {
                from_port = 443
                to_port   = 443
              }
            }
          }
        }
      }
    }
  }

  tags = var.tags
}

resource "aws_networkfirewall_firewall_policy" "this" {
  name = "nfw-policy-${local.name_prefix}"

  firewall_policy {
    stateless_default_actions          = ["aws:drop"]
    stateless_fragment_default_actions = ["aws:drop"]

    stateless_rule_group_reference {
      priority     = 100
      resource_arn = aws_networkfirewall_rule_group.stateless_baseline.arn
    }

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.stateful_allowlist.arn
    }
  }

  tags = var.tags
}

resource "aws_networkfirewall_firewall" "this" {
  name                = "nfw-${local.name_prefix}-${var.aws_region}"
  vpc_id              = aws_vpc.this.id
  firewall_policy_arn = aws_networkfirewall_firewall_policy.this.arn

  dynamic "subnet_mapping" {
    for_each = local.az_map

    content {
      subnet_id = aws_subnet.fw[subnet_mapping.key].id
    }
  }

  tags = var.tags
}

resource "aws_networkfirewall_logging_configuration" "this" {
  count = length(local.firewall_logging_configs) > 0 ? 1 : 0

  firewall_arn = aws_networkfirewall_firewall.this.arn

  logging_configuration {
    dynamic "log_destination_config" {
      for_each = local.firewall_logging_configs

      content {
        log_destination = {
          logGroup = log_destination_config.value
        }
        log_destination_type = "CloudWatchLogs"
        log_type             = log_destination_config.key
      }
    }
  }
}

resource "aws_route_table" "public" {
  for_each = local.az_map
  vpc_id   = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, {
    Name = "rt-${var.project_name}-public-${replace(each.key, var.aws_region, "")}-${var.environment}"
  })
}

resource "aws_route_table" "application" {
  for_each = local.az_map
  vpc_id   = aws_vpc.this.id

  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = aws_ec2_transit_gateway.this.id
  }

  tags = merge(var.tags, {
    Name = "rt-${var.project_name}-app-${replace(each.key, var.aws_region, "")}-${var.environment}"
  })
}

resource "aws_route_table" "data" {
  for_each = local.az_map
  vpc_id   = aws_vpc.this.id

  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = aws_ec2_transit_gateway.this.id
  }

  tags = merge(var.tags, {
    Name = "rt-${var.project_name}-data-${replace(each.key, var.aws_region, "")}-${var.environment}"
  })
}

resource "aws_route_table" "mgmt" {
  for_each = local.az_map
  vpc_id   = aws_vpc.this.id

  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = aws_ec2_transit_gateway.this.id
  }

  tags = merge(var.tags, {
    Name = "rt-${var.project_name}-mgmt-${replace(each.key, var.aws_region, "")}-${var.environment}"
  })
}

resource "aws_route_table" "fw" {
  for_each = local.az_map
  vpc_id   = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[each.key].id
  }

  tags = merge(var.tags, {
    Name = "rt-${var.project_name}-fw-${replace(each.key, var.aws_region, "")}-${var.environment}"
  })
}

resource "aws_route_table" "tgw" {
  for_each = local.az_map
  vpc_id   = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "rt-${var.project_name}-tgw-${replace(each.key, var.aws_region, "")}-${var.environment}"
  })
}

locals {
  firewall_endpoint_by_az = {
    for sync_state in aws_networkfirewall_firewall.this.firewall_status[0].sync_states :
    sync_state.availability_zone => sync_state.attachment[0].endpoint_id
  }
}

resource "aws_route" "tgw_to_firewall" {
  for_each = local.az_map

  route_table_id         = aws_route_table.tgw[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = local.firewall_endpoint_by_az[each.key]

  depends_on = [aws_networkfirewall_firewall.this]
}

resource "aws_route_table_association" "public" {
  for_each       = local.az_map
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public[each.key].id
}

resource "aws_route_table_association" "application" {
  for_each       = local.az_map
  subnet_id      = aws_subnet.app[each.key].id
  route_table_id = aws_route_table.application[each.key].id
}

resource "aws_route_table_association" "data" {
  for_each       = local.az_map
  subnet_id      = aws_subnet.data[each.key].id
  route_table_id = aws_route_table.data[each.key].id
}

resource "aws_route_table_association" "fw" {
  for_each       = local.az_map
  subnet_id      = aws_subnet.fw[each.key].id
  route_table_id = aws_route_table.fw[each.key].id
}

resource "aws_route_table_association" "tgw" {
  for_each       = local.az_map
  subnet_id      = aws_subnet.tgw[each.key].id
  route_table_id = aws_route_table.tgw[each.key].id
}

resource "aws_route_table_association" "mgmt" {
  for_each       = local.az_map
  subnet_id      = aws_subnet.mgmt[each.key].id
  route_table_id = aws_route_table.mgmt[each.key].id
}

resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = [for az in var.azs : aws_subnet.public[az].id]

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "deny"
    cidr_block = "10.0.0.0/8"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 110
    action     = "deny"
    cidr_block = "172.16.0.0/12"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 120
    action     = "deny"
    cidr_block = "192.168.0.0/16"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(var.tags, {
    Name = "nacl-${var.project_name}-public-${var.environment}"
  })
}

resource "aws_security_group" "alb" {
  name        = "sg-${var.project_name}-allow-alb-${var.environment}"
  description = "ALB security group"
  vpc_id      = aws_vpc.this.id

  tags = var.tags
}

resource "aws_security_group" "node" {
  name        = "sg-${var.project_name}-eks-node-${var.environment}"
  description = "EKS node security group"
  vpc_id      = aws_vpc.this.id

  tags = var.tags
}

resource "aws_security_group" "data" {
  name        = "sg-${var.project_name}-data-${var.environment}"
  description = "Data-tier security group"
  vpc_id      = aws_vpc.this.id

  tags = var.tags
}

resource "aws_security_group" "mgmt" {
  name        = "sg-${var.project_name}-mgmt-${var.environment}"
  description = "Management security group"
  vpc_id      = aws_vpc.this.id

  tags = var.tags
}

resource "aws_security_group" "endpoint" {
  count = var.enable_vpc_endpoints ? 1 : 0

  name        = "sg-${var.project_name}-vpce-${var.environment}"
  description = "VPC endpoint interface security group"
  vpc_id      = aws_vpc.this.id

  tags = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_nodeport" {
  security_group_id            = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 30000
  to_port                      = 32767
  referenced_security_group_id = aws_security_group.node.id
}

resource "aws_vpc_security_group_ingress_rule" "node_from_alb_nodeport" {
  security_group_id            = aws_security_group.node.id
  ip_protocol                  = "tcp"
  from_port                    = 30000
  to_port                      = 32767
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_ingress_rule" "node_self" {
  security_group_id            = aws_security_group.node.id
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.node.id
}

resource "aws_vpc_security_group_egress_rule" "node_egress_https" {
  security_group_id = aws_security_group.node.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "data_postgres_from_node" {
  security_group_id            = aws_security_group.data.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.node.id
}

resource "aws_vpc_security_group_egress_rule" "data_all" {
  security_group_id = aws_security_group.data.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "mgmt_https" {
  security_group_id = aws_security_group.mgmt.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "endpoint_https_from_vpc" {
  count = var.enable_vpc_endpoints ? 1 : 0

  security_group_id = aws_security_group.endpoint[0].id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = var.vpc_cidr
}

resource "aws_vpc_endpoint" "interface" {
  for_each = var.enable_vpc_endpoints ? local.interface_endpoint_services : {}

  vpc_id              = aws_vpc.this.id
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.aws_region}.${each.value}"
  subnet_ids          = [for az in var.azs : aws_subnet.app[az].id]
  security_group_ids  = [aws_security_group.endpoint[0].id]
  policy              = var.enable_restrictive_endpoint_policies ? local.interface_endpoint_policies[each.key] : null

  tags = merge(var.tags, {
    Name = "vpce-${var.project_name}-${each.key}-${var.environment}"
  })
}

resource "aws_vpc_endpoint" "s3_gateway" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id            = aws_vpc.this.id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  policy            = var.enable_restrictive_endpoint_policies ? local.s3_gateway_endpoint_policy : null
  route_table_ids = concat(
    [for az in var.azs : aws_route_table.application[az].id],
    [for az in var.azs : aws_route_table.data[az].id],
    [for az in var.azs : aws_route_table.mgmt[az].id]
  )

  tags = merge(var.tags, {
    Name = "vpce-${var.project_name}-s3-${var.environment}"
  })
}
