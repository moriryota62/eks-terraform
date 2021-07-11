terraform {
  required_version = ">= 0.13.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket         = "PJ-ENV-tfstate"
    key            = "eks-terraform/terraform.tfstate"
    encrypt        = true
    dynamodb_table = "PJ-ENV-tfstate-lock"
    region         = "REGION"
  }
}