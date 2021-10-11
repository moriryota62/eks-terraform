resource "aws_kinesis_firehose_delivery_stream" "container_insights" {
  for_each = var.log_groups

  name        = "${var.base_name}-logarchive-${each.key}"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.kinesis.arn
    bucket_arn = aws_s3_bucket.container_insights["${each.key}"].arn

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.kinesis["${each.key}"].name
      log_stream_name = aws_cloudwatch_log_stream.kinesis["${each.key}"].name
    }
  }
}