data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = "project-environment-tfstate"
    key    = "network/terraform.tfstate"
    region = "us-east-2"
  }
}

data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = "project-environment-tfstate"
    key    = "eks/terraform.tfstate"
    region = "us-east-2"
  }
}