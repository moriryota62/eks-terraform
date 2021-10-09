resource "aws_route53_zone" "this" {
  name          = var.zone_name
  force_destroy = true

  vpc {
    vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  }

}