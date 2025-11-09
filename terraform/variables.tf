variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "user-registration"
}

variable "table_name" {
  description = "DynamoDB table name"
  type        = string
  default     = "users"
}

variable "sender_email" {
  description = "Email address for sending notifications (must be verified in SES)"
  type        = string
  default     = "noreply@example.com"
}
