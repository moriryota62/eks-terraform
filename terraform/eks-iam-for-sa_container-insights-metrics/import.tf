data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = "project-environment-tfstate"
    key    = "eks/terraform.tfstate"
    region = "us-east-2"
  }
}