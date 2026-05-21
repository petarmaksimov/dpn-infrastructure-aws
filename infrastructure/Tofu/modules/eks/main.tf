locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.endpoint_public_access_cidrs
    security_group_ids      = [var.node_security_group_id]
  }

  enabled_cluster_log_types = var.cluster_log_types

  encryption_config {
    provider {
      key_arn = var.kms_key_arn
    }
    resources = ["secrets"]
  }

  tags = merge(var.tags, {
    Name = var.cluster_name
  })
}

resource "aws_eks_node_group" "system" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = var.system_node_group.name
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = var.system_node_group.desired_size
    min_size     = var.system_node_group.min_size
    max_size     = var.system_node_group.max_size
  }

  instance_types = var.system_node_group.instance_types
  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "ON_DEMAND"

  tags = merge(var.tags, {
    Name = "ng-${local.name_prefix}-system"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eks_node_group" "workload" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = var.workload_node_group.name
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = var.workload_node_group.desired_size
    min_size     = var.workload_node_group.min_size
    max_size     = var.workload_node_group.max_size
  }

  instance_types = var.workload_node_group.instance_types
  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "ON_DEMAND"

  labels = {
    workload = "true"
  }

  tags = merge(var.tags, {
    Name = "ng-${local.name_prefix}-workload"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_openid_connect_provider" "this" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer

  tags = var.tags
}
