terraform {
  required_version = ">= 0.13.5"
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