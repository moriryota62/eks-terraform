resource "aws_eks_cluster" "this" {
  name     = var.base_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.eks_version

  vpc_config {
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
    security_group_ids      = []
    subnet_ids              = flatten([var.private_subnet_ids, var.public_subnet_ids])
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  encryption_config {
    provider {
      key_arn = var.kms_arn
    }
    resources = ["secrets"]
  }

  tags = merge(
    {
      "Name" = var.base_name
    },
    var.tags
  )

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
  ]
}