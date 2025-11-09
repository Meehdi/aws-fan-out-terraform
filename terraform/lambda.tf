
# Data source to create ZIP archive for Orchestrator Lambda
data "archive_file" "orchestrator" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/orchestrator/dist"
  output_path = "${path.module}/../lambdas/orchestrator/lambda.zip"
}

# Data source to create ZIP archive for DB Writer Lambda
data "archive_file" "db_writer" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/db-writer/dist"
  output_path = "${path.module}/../lambdas/db-writer/lambda.zip"
}

# Data source to create ZIP archive for Email Sender Lambda
data "archive_file" "email_sender" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/email-sender/dist"
  output_path = "${path.module}/../lambdas/email-sender/lambda.zip"
}

# Lambda Function - Orchestrator
resource "aws_lambda_function" "orchestrator" {
  filename         = data.archive_file.orchestrator.output_path
  function_name    = "${var.project_name}-orchestrator"
  role             = aws_iam_role.lambda_execution.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.orchestrator.output_base64sha256
  runtime          = "nodejs20.x"
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      TABLE_NAME    = aws_dynamodb_table.users.name
      SNS_TOPIC_ARN = aws_sns_topic.user_registration.arn
    }
  }

  tags = {
    Name        = "${var.project_name}-orchestrator"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# Lambda Function - DB Writer
resource "aws_lambda_function" "db_writer" {
  filename         = data.archive_file.db_writer.output_path
  function_name    = "${var.project_name}-db-writer"
  role             = aws_iam_role.lambda_execution.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.db_writer.output_base64sha256
  runtime          = "nodejs20.x"
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.users.name
    }
  }

  tags = {
    Name        = "${var.project_name}-db-writer"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# Lambda Function - Email Sender
resource "aws_lambda_function" "email_sender" {
  filename         = data.archive_file.email_sender.output_path
  function_name    = "${var.project_name}-email-sender"
  role             = aws_iam_role.lambda_execution.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.email_sender.output_base64sha256
  runtime          = "nodejs20.x"
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      SENDER_EMAIL = var.sender_email
    }
  }

  tags = {
    Name        = "${var.project_name}-email-sender"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# Event Source Mapping - SQS to DB Writer Lambda
resource "aws_lambda_event_source_mapping" "db_writer" {
  event_source_arn = aws_sqs_queue.db_writer.arn
  function_name    = aws_lambda_function.db_writer.arn
  batch_size       = 10
  enabled          = true
}

# Event Source Mapping - SQS to Email Sender Lambda
resource "aws_lambda_event_source_mapping" "email_sender" {
  event_source_arn = aws_sqs_queue.email_sender.arn
  function_name    = aws_lambda_function.email_sender.arn
  batch_size       = 10
  enabled          = true
}

# CloudWatch Log Group for Orchestrator
resource "aws_cloudwatch_log_group" "orchestrator" {
  name              = "/aws/lambda/${aws_lambda_function.orchestrator.function_name}"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-orchestrator-logs"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# CloudWatch Log Group for DB Writer
resource "aws_cloudwatch_log_group" "db_writer" {
  name              = "/aws/lambda/${aws_lambda_function.db_writer.function_name}"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-db-writer-logs"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# CloudWatch Log Group for Email Sender
resource "aws_cloudwatch_log_group" "email_sender" {
  name              = "/aws/lambda/${aws_lambda_function.email_sender.function_name}"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-email-sender-logs"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}