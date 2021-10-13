resource "aws_s3_bucket" "container_insights" {
  for_each = var.log_groups

  bucket = "${var.base_name}-logarchive-${each.key}"
  acl    = "private"

  lifecycle_rule {
    enabled = true

    transition {
      days          = each.value.transition_glacier_days
      storage_class = "GLACIER"
    }
  }

  tags = {
      "Name" = "${var.base_name}-logarchive-${each.key}"
  }
}