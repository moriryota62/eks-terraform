resource "aws_kms_key" "this" {
  description         = "${var.base_name} secret encrypt key"
  enable_key_rotation = true

  tags = merge(
    {
      "Name" = "${var.base_name}-k8s-secret"
    },
    var.tags
  )
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.base_name}-k8s-secret"
  target_key_id = aws_kms_key.this.key_id
}