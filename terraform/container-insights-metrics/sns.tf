resource "aws_sns_topic" "metrics" {
  name = "${var.base_name}-metrics-topic"

  tags = {
    "Name" = "${var.base_name}-metrics-topic"
  }
}

resource "aws_sns_topic_subscription" "metrics-subscribe" {
  for_each = toset(var.endpoint)

  topic_arn = aws_sns_topic.metrics.arn
  protocol  = "email"
  endpoint  = each.key
}
