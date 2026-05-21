output "kms_key_arn" {
  description = "KMS key arn"
  value       = aws_kms_key.this.arn
}

output "kms_key_id" {
  description = "KMS key id"
  value       = aws_kms_key.this.key_id
}

output "eks_cluster_role_arn" {
  description = "IAM role arn used by EKS control plane"
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_node_role_arn" {
  description = "IAM role arn used by EKS worker nodes"
  value       = aws_iam_role.eks_node.arn
}
