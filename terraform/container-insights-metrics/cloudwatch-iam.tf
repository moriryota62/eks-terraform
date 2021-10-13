resource "aws_iam_role" "container_insights" {
  name = "${var.base_name}-container-insights-metrics"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "logs.${data.aws_region.current.name}.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })

  tags = {
    "Name" = "${var.base_name}-container-insights-metrics"
  }
}

resource "aws_iam_policy" "container_insights" {
  name  = "${var.base_name}-container-insights-metrics"

  

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "firehose:*"
            ],
            "Resource": ${jsonencode(values(aws_kinesis_firehose_delivery_stream.container_insights)[*].arn)} ,
            "Effect": "Allow"
        }
    ]
}
EOF

  tags = {
    "Name" = "${var.base_name}-container-insights-metrics"
  }
}

resource "aws_iam_role_policy_attachment" "container_insights" {
  policy_arn = aws_iam_policy.container_insights.arn
  role       = aws_iam_role.container_insights.name
}

