resource "aws_kms_key" "this" {
  description         = "${var.base_name} EFS encrypt key"
  enable_key_rotation = true

  tags = {
    "Name" = "${var.base_name}-EFS-key"
  }
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.base_name}-EFS-key"
  target_key_id = aws_kms_key.this.key_id
}