resource "aws_eip" "natgw" {
  count = length(var.subnet_public_cidrs)
  vpc   = true

  tags = merge(
    {
      "Name" = "${var.base_name}-natgw-eip-${count.index}"
    },
    var.tags
  )
}