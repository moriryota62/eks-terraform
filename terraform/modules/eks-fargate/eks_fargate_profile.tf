resource "aws_eks_fargate_profile" "this" {
  cluster_name           = var.cluster_name
  fargate_profile_name   = "${var.base_name}-${var.namespace_name}"
  pod_execution_role_arn = var.fargate_iam_arn
  subnet_ids             = var.private_subnet_ids

  selector {
    namespace = var.namespace_name
    labels    = var.labels
  }

  tags = merge(
    {
      "Name" = "${var.base_name}-${var.namespace_name}"
    },
    var.tags
  )
}