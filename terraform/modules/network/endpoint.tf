data "aws_region" "current" {}

resource "aws_vpc_endpoint" "ecr_api" {
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  vpc_id              = aws_vpc.main.id
  subnet_ids          = aws_subnet.private.*.id
  security_group_ids  = [aws_security_group.ecr_endpoint.id]
  private_dns_enabled = true

  tags = merge(
    {
      "Name" = "${var.base_name}-ECR-API-Endpoint"
    },
    var.tags
  )
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  vpc_id              = aws_vpc.main.id
  subnet_ids          = aws_subnet.private.*.id
  security_group_ids  = [aws_security_group.ecr_endpoint.id]
  private_dns_enabled = true

  tags = merge(
    {
      "Name" = "${var.base_name}-ECR-DKR-Endpoint"
    },
    var.tags
  )
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id          = aws_vpc.main.id
  service_name    = "com.amazonaws.${data.aws_region.current.name}.s3"
  route_table_ids = flatten([aws_route_table.public.id, [aws_route_table.private.*.id]])

  tags = merge(
    {
      "Name" = "${var.base_name}-S3-Endpoint"
    },
    var.tags
  )
}

# com.amazonaws.Region.logs