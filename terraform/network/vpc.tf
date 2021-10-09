resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    "Name"                                   = "${var.base_name}-vpc",
    "kubernetes.io/cluster/${var.base_name}" = "shared"
  }
}