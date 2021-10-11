resource "aws_lambda_permission" "logging" {
  for_each = {
    for k, r in var.log_groups : k => r
    if r.filter_pattern != null
  }

  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.log.function_name
  principal     = "logs.${data.aws_region.current.name}.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.container_insights["${each.key}"].arn}:*"
}