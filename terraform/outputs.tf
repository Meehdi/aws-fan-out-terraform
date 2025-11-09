output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.users.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.users.arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic"
  value       = aws_sns_topic.user_registration.arn
}

output "db_writer_queue_url" {
  description = "URL of the DB writer SQS queue"
  value       = aws_sqs_queue.db_writer.url
}

output "email_sender_queue_url" {
  description = "URL of the email sender SQS queue"
  value       = aws_sqs_queue.email_sender.url
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_execution.arn
}

output "orchestrator_function_name" {
  description = "Name of the orchestrator Lambda function"
  value       = aws_lambda_function.orchestrator.function_name
}

output "orchestrator_function_arn" {
  description = "ARN of the orchestrator Lambda function"
  value       = aws_lambda_function.orchestrator.arn
}

output "db_writer_function_name" {
  description = "Name of the DB writer Lambda function"
  value       = aws_lambda_function.db_writer.function_name
}

output "email_sender_function_name" {
  description = "Name of the email sender Lambda function"
  value       = aws_lambda_function.email_sender.function_name
}