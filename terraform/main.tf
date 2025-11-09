# DynamoDB Table for storing users

resource "aws_dynamodb_table" "users" {
  name           = var.table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "email"

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
