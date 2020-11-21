terraform {
  required_version = ">= 0.13.5"
}

provider "aws" {
  version = ">= 3.5.0"
  region  = "us-east-2"
}

# parameter settings
locals {
  # common parameter
  pj        = "PJ"
  env       = "ENV"
  base_name = "${local.pj}-${local.env}"
  tags = {
    pj    = "PJ"
    env   = "ENV"
    owner = "OWNER"
  }
}

resource "aws_s3_bucket" "tfstate" {
  bucket        = "${lower(local.base_name)}-tfstate"
  acl           = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = merge(
  {
    "Name" = "${lower(local.base_name)}-tfstate"
  },
  local.tags
  )
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "tfstate_lock" {
  name           = "${local.base_name}-tfstate-lock"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}