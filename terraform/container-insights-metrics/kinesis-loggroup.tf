resource "aws_cloudwatch_log_group" "kinesis" {
  for_each = var.log_groups

  name = "/aws/kinesisfirehose/${var.base_name}/logarchive/${each.key}"

  retention_in_days = 1

  tags = {
    "Name" = "/aws/kinesisfirehose/${var.base_name}/logarchive/${each.key}"
  }
}

resource "aws_cloudwatch_log_stream" "kinesis" {
  for_each = var.log_groups

  name           = "${var.base_name}-archive-stream-${each.key}"
  log_group_name = aws_cloudwatch_log_group.kinesis["${each.key}"].name
}