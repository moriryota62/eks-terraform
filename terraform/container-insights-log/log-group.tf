resource "aws_cloudwatch_log_group" "container_insights" {
  for_each = var.log_groups

  name = "/aws/containerinsights/${data.terraform_remote_state.eks.outputs.cluster_name}/${each.key}"

  retention_in_days = each.value.retention_in_days

  tags = {
    "Name" = "/aws/containerinsights/${data.terraform_remote_state.eks.outputs.cluster_name}/application"
  }
}
