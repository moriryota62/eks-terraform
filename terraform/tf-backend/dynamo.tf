resource "aws_dynamodb_table" "tfstate_lock" {
  name           = "${var.base_name}-tfstate-lock"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    "Name" = "${var.base_name}-tfstate-lock"
  }
}