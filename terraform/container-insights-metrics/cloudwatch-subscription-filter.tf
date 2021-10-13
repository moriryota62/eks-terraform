resource "aws_cloudwatch_log_subscription_filter" "container_insights" {
  for_each = var.log_groups

  name            = "${var.base_name}-logfilter-${each.key}"
  role_arn        = aws_iam_role.container_insights.arn
  log_group_name  = "/aws/containerinsights/${data.terraform_remote_state.eks.outputs.cluster_name}/${each.key}"
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.container_insights["${each.key}"].arn
}
