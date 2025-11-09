# HTTP API Gateway
resource "aws_apigatewayv2_api" "user_registration" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"
  description   = "User Registration API with fan-out pattern"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "GET", "OPTIONS"]
    allow_headers = ["content-type", "authorization"]
    max_age       = 300
  }

  tags = {
    Name        = "${var.project_name}-api"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# API Gateway Stage (auto-deploy)
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.user_registration.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = {
    Name        = "${var.project_name}-api-stage"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.project_name}-api"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-api-logs"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# Lambda Integration
resource "aws_apigatewayv2_integration" "orchestrator" {
  api_id                 = aws_apigatewayv2_api.user_registration.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.orchestrator.invoke_arn
  payload_format_version = "2.0"
}

# Route: POST /users
resource "aws_apigatewayv2_route" "create_user" {
  api_id    = aws_apigatewayv2_api.user_registration.id
  route_key = "POST /users"
  target    = "integrations/${aws_apigatewayv2_integration.orchestrator.id}"
}

# Lambda Permission - Allow API Gateway to invoke Lambda
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.orchestrator.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.user_registration.execution_arn}/*/*"
}