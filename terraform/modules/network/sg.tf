resource "aws_security_group" "ecr_endpoint" {
  name        = "${var.base_name}-ecr-endpoint-sg"
  vpc_id      = aws_vpc.main.id
  description = "For ECR Endpoint"

  tags = merge(
    {
      "Name" = "${var.base_name}-ecr-endpoint-sg"
    },
    var.tags
  )

  ingress {
    description = "Allow ECR access from subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = flatten([var.subnet_public_cidrs, var.subnet_private_cidrs])
  }

  egress {
    description = "Allow any"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
