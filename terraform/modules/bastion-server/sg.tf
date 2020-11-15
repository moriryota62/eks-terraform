resource "aws_security_group" "bastion" {
  name        = "${var.base_name}-bastion-sg"
  vpc_id      = var.vpc_id
  description = "For Bastion EC2"

  tags = merge(
    {
      "Name" = "${var.base_name}-bastion-sg"
    },
    var.tags
  )

  ingress {
    description = "Allow work PC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.sg_allow_access_cidrs
  }

  egress {
    description = "Allow any outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
