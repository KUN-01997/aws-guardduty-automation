output "sns_topic_arn" {
  value = aws_sns_topic.alert_topic.arn
}

output "lambda_function_name" {
  value = aws_lambda_function.alert_handler.function_name
}
