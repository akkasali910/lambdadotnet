# outputs.tf

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.api_consumer.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.api_consumer.function_name
}

output "api_endpoint" {
  description = "HTTP API endpoint"
  value       = aws_apigatewayv2_api.lambda_api.api_endpoint
}

output "cloudwatch_log_group" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

