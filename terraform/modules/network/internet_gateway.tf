resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      "Name" = "${var.base_name}-internet-gateway"
    },
    var.tags
  )
}