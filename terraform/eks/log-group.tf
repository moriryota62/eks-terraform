resource "aws_cloudwatch_log_group" "eks-cluster" {

  name = "/aws/eks/${var.base_name}/cluster"

  retention_in_days = var.retention_in_days

  tags = {
    "Name" = "/aws/eks/${var.base_name}/cluster"
  }
}
