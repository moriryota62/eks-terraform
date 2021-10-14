resource "aws_iam_role" "kinesis" {
  name = "${var.base_name}-kinesis-container-insights-metris"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "firehose.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })

  tags = {
    "Name" = "${var.base_name}-kinesis-container-insights-metris"
  }
}

resource "aws_iam_policy" "kinesis" {
  name = "${var.base_name}-kinesis-container-insights-metris"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "logs:PutLogEvents"
            ],
            "Resource": ${jsonencode(values(aws_cloudwatch_log_group.container_insights)[*].arn)} ,
            "Effect": "Allow"
        },
        {
            "Action": [
                "s3:AbortMultipartUpload",
                "s3:GetBucketLocation",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads",
                "s3:PutObject"
            ],
            "Resource": ${jsonencode([for d in aws_s3_bucket.container_insights : "${d.arn}/*"])} ,
            "Effect": "Allow"
        }
    ]
}
EOF

  tags = {
    "Name" = "${var.base_name}-kinesis-container-insights-metris"
  }
}

resource "aws_iam_role_policy_attachment" "kinesis" {
  policy_arn = aws_iam_policy.kinesis.arn
  role       = aws_iam_role.kinesis.name
}