output "vpc_id" {
  description = "VPC id"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public subnet ids"
  value       = [for az in var.azs : aws_subnet.public[az].id]
}

output "application_subnet_ids" {
  description = "Application subnet ids"
  value       = [for az in var.azs : aws_subnet.app[az].id]
}

output "data_subnet_ids" {
  description = "Data subnet ids"
  value       = [for az in var.azs : aws_subnet.data[az].id]
}

output "management_subnet_ids" {
  description = "Management subnet ids"
  value       = [for az in var.azs : aws_subnet.mgmt[az].id]
}

output "alb_security_group_id" {
  description = "ALB security group id"
  value       = aws_security_group.alb.id
}

output "node_security_group_id" {
  description = "EKS node security group id"
  value       = aws_security_group.node.id
}

output "data_security_group_id" {
  description = "Data tier security group id"
  value       = aws_security_group.data.id
}

output "management_security_group_id" {
  description = "Management tier security group id"
  value       = aws_security_group.mgmt.id
}

output "transit_gateway_id" {
  description = "Transit gateway id"
  value       = aws_ec2_transit_gateway.this.id
}

output "network_firewall_arn" {
  description = "Network firewall arn"
  value       = aws_networkfirewall_firewall.this.arn
}

output "interface_vpc_endpoint_ids" {
  description = "Interface VPC endpoint ids keyed by service"
  value       = { for k, v in aws_vpc_endpoint.interface : k => v.id }
}

output "s3_gateway_vpc_endpoint_id" {
  description = "S3 gateway VPC endpoint id"
  value       = try(aws_vpc_endpoint.s3_gateway[0].id, null)
}
