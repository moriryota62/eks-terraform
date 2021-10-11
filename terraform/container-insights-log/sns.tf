resource "aws_sns_topic" "log" {
  name = "${var.base_name}-log-topic"

  tags = {
    "Name" = "${var.base_name}-log-topic"
  }
}

resource "aws_sns_topic_subscription" "log-subscribe" {
  for_each = toset(var.endpoint)

  topic_arn = aws_sns_topic.log.arn
  protocol  = "email"
  endpoint  = each.key
}
