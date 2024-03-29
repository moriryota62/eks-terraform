resource "aws_iam_role" "log-lambda" {
  name = "${var.base_name}-log-lambda"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })

  tags = {
    "Name" = "${var.base_name}-log-lambda"
  }
}

resource "aws_iam_role_policy_attachment" "log-lambda" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
  role       = aws_iam_role.log-lambda.name
}

resource "aws_iam_role_policy_attachment" "log-lambda-cloudwatch-logs" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.log-lambda.name
}

resource "aws_iam_role_policy_attachment" "log-lambda-s3" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.log-lambda.name
}
