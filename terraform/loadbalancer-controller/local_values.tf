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
