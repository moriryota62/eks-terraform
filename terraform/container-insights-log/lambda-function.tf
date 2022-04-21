data "archive_file" "function_source" {
  type        = "zip"
  source_dir  = "lambda-code"
  output_path = "subscription.zip"
}

resource "aws_lambda_function" "log" {
  filename      = "./subscription.zip"
  function_name = "${var.base_name}-container-insights-log-alert"
  role          = aws_iam_role.log-lambda.arn
  handler       = "subscription.lambda_handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = filebase64sha256("./subscription.zip")

  runtime = "python3.7"

  environment {
    variables = {
      SNS_TOPIC_ARN    = aws_sns_topic.log.arn,
      ALARM_SUBJECT    = "[${var.base_name}] Container Insights detected log message!"
      BUCKET_NAME      = "${var.base_name}-logalertfilter"
      FILTER_FILE_NAME = "log-filtering-parameter.txt"
    }
  }

  tags = {
    "Name" = "${var.base_name}-container-insights-log-alert"
    "Name" = "${var.base_name}-log-alert"
  }
}
