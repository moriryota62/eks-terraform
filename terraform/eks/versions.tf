terraform {
  required_version = ">= 0.13.5"

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket         = "project-environment-tfstate"
    key            = "eks/terraform.tfstate"
    encrypt        = true
    dynamodb_table = "project-environment-tfstate-lock"
    region         = "ap-northeast-1"
  }
}

provider "aws" {
  region = "ap-northeast-1"
  default_tags {
    tags = {
      pj    = "project"
      env   = "environment"
      owner = "owner"
    }
  }
}