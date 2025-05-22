provider "aws" {
  region = var.aws_region
}

resource "aws_guardduty_detector" "main" {
  enable = true
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_guardduty_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_sns_topic" "alert_topic" {
  name = "guardduty-alerts-topic"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.alert_topic.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_lambda_function" "alert_handler" {
  filename         = "lambda.zip"
  function_name    = "guardduty_alert_handler"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("lambda.zip")
  timeout          = 10

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.alert_topic.arn
      DEDUP_TABLE   = aws_dynamodb_table.dedup_table.name
    }
  }
}


resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.alert_handler.function_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_event_rule" "guardduty_finding" {
  name        = "guardduty-finding-rule"
  description = "Triggers on GuardDuty findings"
  event_pattern = jsonencode({
    source = ["aws.guardduty"],
    "detail-type": ["GuardDuty Finding"]
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.guardduty_finding.name
  target_id = "SendToLambda"
  arn       = aws_lambda_function.alert_handler.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alert_handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_finding.arn
}

resource "aws_iam_policy" "lambda_sns_publish" {
  name = "LambdaSNSPublishPolicy"
  description = "Allow Lambda to publish to SNS"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sns:Publish"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_sns_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_sns_publish.arn
}

resource "aws_dynamodb_table" "dedup_table" {
  name         = "guardduty-dedup-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "finding_id"

  attribute {
    name = "finding_id"
    type = "S"
  }
}

resource "aws_iam_policy" "lambda_dynamodb_access" {
  name = "LambdaDynamoDBAccess"
  description = "Allow Lambda to Get/Put items in DynamoDB"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem"
        ],
        Resource = aws_dynamodb_table.dedup_table.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb_access.arn
}
