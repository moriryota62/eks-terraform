resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  vpc      = true

  tags = {
    "Name" = "${var.base_name}-bastion-eip"
  }
}