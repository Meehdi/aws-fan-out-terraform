# DynamoDB Table for storing users

resource "aws_dynamodb_table" "users" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "email"

  attribute {
    name = "email"
    type = "S"
  }

  tags = {
    Name        = "${var.project_name}-table"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# SNS Topic for fan-out pattern
resource "aws_sns_topic" "user_registration" {
  name = "${var.project_name}-topic"

  tags = {
    Name        = "${var.project_name}-topic"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# SQS Queue for DB Writer Lambda
resource "aws_sqs_queue" "db_writer" {
  name                       = "${var.project_name}-db-writer-queue"
  visibility_timeout_seconds = 300   # 5 minutes (Lambda timeout * 6)
  message_retention_seconds  = 86400 # 1 day

  tags = {
    Name        = "${var.project_name}-db-writer-queue"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# SQS Queue for Email Sender Lambda
resource "aws_sqs_queue" "email_sender" {
  name                       = "${var.project_name}-email-sender-queue"
  visibility_timeout_seconds = 300
  message_retention_seconds  = 86400

  tags = {
    Name        = "${var.project_name}-email-sender-queue"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# IAM Policy Document for DB Writer Queue (data source)
data "aws_iam_policy_document" "db_writer_queue" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions = [
      "SQS:SendMessage"
    ]

    resources = [
      aws_sqs_queue.db_writer.arn
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.user_registration.arn]
    }
  }
}

# Apply the policy to DB Writer Queue
resource "aws_sqs_queue_policy" "db_writer" {
  queue_url = aws_sqs_queue.db_writer.id
  policy    = data.aws_iam_policy_document.db_writer_queue.json
}

# IAM Policy Document for Email Sender Queue (data source)
data "aws_iam_policy_document" "email_sender_queue" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions = [
      "SQS:SendMessage"
    ]

    resources = [
      aws_sqs_queue.email_sender.arn
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.user_registration.arn]
    }
  }
}

# Apply the policy to Email Sender Queue
resource "aws_sqs_queue_policy" "email_sender" {
  queue_url = aws_sqs_queue.email_sender.id
  policy    = data.aws_iam_policy_document.email_sender_queue.json
}

# SNS Topic Subscription - DB Writer Queue
resource "aws_sns_topic_subscription" "db_writer" {
  topic_arn = aws_sns_topic.user_registration.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.db_writer.arn
}

# SNS Topic Subscription - Email Sender Queue
resource "aws_sns_topic_subscription" "email_sender" {
  topic_arn = aws_sns_topic.user_registration.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.email_sender.arn
}
