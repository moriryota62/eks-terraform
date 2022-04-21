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

resource "aws_s3_bucket" "logalertfilter" {
  bucket = "${var.base_name}-logalertfilter"
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = {
    "Name" = "${var.base_name}-logfilter"
  }
}

resource "aws_s3_bucket_object" "log-filtering-parameter" {
  bucket = aws_s3_bucket.logalertfilter.id
  key    = "log-filtering-parameter.txt"
  source = "./filter-file/log-filtering-parameter.txt"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("./filter-file/log-filtering-parameter.txt")

  tags = {
    "Name" = "${var.base_name}-log-filtering-parameter.txt"
  }
}
