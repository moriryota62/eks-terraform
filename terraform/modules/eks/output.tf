output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "nodegroup_iam_arn" {
  value = aws_iam_role.eks_node_group.arn
}

output "fargate_iam_arn" {
  value = aws_iam_role.fargate_profile.arn
}
