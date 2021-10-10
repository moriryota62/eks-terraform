terraform {
  required_version = ">= 0.13.5"

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket         = "project-environment-tfstate"
    key            = "eks-iam-for-sa_container-insights-log/terraform.tfstate"
    encrypt        = true
    dynamodb_table = "project-environment-tfstate-lock"
    region         = "us-east-2"
  }
}

provider "aws" {
  region = "us-east-2"
  default_tags {
    tags = {
      pj    = "project"
      env   = "environment"
      owner = "owner"
    }
  }
}