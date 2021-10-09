resource "aws_eks_fargate_profile" "this" {
  for_each = var.eks-fargate_profiles

  cluster_name           = data.terraform_remote_state.eks.outputs.cluster_name
  fargate_profile_name   = each.key
  pod_execution_role_arn = data.terraform_remote_state.eks.outputs.fargate_iam_arn
  subnet_ids             = data.terraform_remote_state.network.outputs.private_subnet_ids

  selector {
    namespace = each.value.namespace
    labels    = each.value.labels
  }

  tags = merge(
    {
      "Name" = each.key
    }
  )
}