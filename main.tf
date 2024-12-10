# main.tf

provider "aws" {
  region = "eu-west-1"  # Change to your desired region
}

# Lambda function
resource "aws_lambda_function" "api_consumer" {
  filename         = "function.zip"
  function_name    = "ApiConsumerFunction"
  role            = aws_iam_role.lambda_role.arn
  handler         = "ApiConsumerFunction::ApiConsumerFunction.Function::FunctionHandler"
  runtime         = "dotnet8"
  timeout         = 30
  memory_size     = 256

  environment {
    variables = {
      ASPNETCORE_ENVIRONMENT = "Production"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.lambda_logs,
  ]
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/ApiConsumerFunction"
  retention_in_days = 14
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "api_consumer_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for CloudWatch Logs
resource "aws_iam_policy" "lambda_logging" {
  name        = "api_consumer_lambda_logging"
  description = "IAM policy for logging from a lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# DynamoDB Table
resource "aws_dynamodb_table" "api_responses" {
  name           = "api_responses"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "search_term"
    type = "S"
  }

  global_secondary_index {
    name               = "search_term_index"
    hash_key          = "search_term"
    projection_type    = "ALL"
  }

  tags = {
    Environment = var.environment
  }
}

# Add DynamoDB permissions to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb.arn
}

# DynamoDB policy
resource "aws_iam_policy" "lambda_dynamodb" {
  name        = "api_consumer_lambda_dynamodb"
  description = "IAM policy for DynamoDB access from lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.api_responses.arn,
          "${aws_dynamodb_table.api_responses.arn}/index/*"
        ]
      }
    ]
  })
}

# Attach logging policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

# Function URL (Optional - if you want to access the Lambda via HTTP)
resource "aws_lambda_function_url" "api_consumer_url" {
  function_name      = aws_lambda_function.api_consumer.function_name
  authorization_type = "NONE"
}

# Optional API Gateway integration
resource "aws_apigatewayv2_api" "lambda_api" {
  name          = "api-consumer-http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda_stage" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  name   = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id = aws_apigatewayv2_api.lambda_api.id

  integration_uri    = aws_lambda_function.api_consumer.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "lambda_route" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  route_key = "POST /search"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_consumer.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/*"
}
