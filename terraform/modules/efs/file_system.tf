resource "aws_efs_file_system" "this" {
  creation_token = var.base_name
  encrypted      = true
  kms_key_id     = var.kms_id

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = merge(
    {
      "Name" = "${var.base_name}-efs"
    },
    var.tags
  )
}