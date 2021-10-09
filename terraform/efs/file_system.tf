resource "aws_efs_file_system" "this" {
  creation_token = var.base_name
  encrypted      = true
  kms_key_id     = aws_kms_key.this.arn

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    "Name" = "${var.base_name}-efs"
  }
}