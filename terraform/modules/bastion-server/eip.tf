resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  vpc      = true

  tags = merge(
    {
      "Name" = "${var.base_name}-bastion-eip"
    },
    var.tags
  )
}