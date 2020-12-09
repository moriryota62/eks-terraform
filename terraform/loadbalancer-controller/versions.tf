terraform {
  required_version = ">= 0.13.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.13.0"
    }
  }

  backend "s3" {
    bucket         = "pj-env-tfstate"
    key            = "lb-controller/terraform.tfstate"
    encrypt        = true
    dynamodb_table = "PJ-ENV-tfstate-lock"
    region         = "us-east-2"
  }
}