resource "aws_eks_node_group" "this" {
  cluster_name    = data.terraform_remote_state.eks.outputs.cluster_name
  node_group_name = "${var.base_name}-${var.node_role}-node-group"
  node_role_arn   = data.terraform_remote_state.eks.outputs.nodegroup_iam_arn
  subnet_ids      = data.terraform_remote_state.network.outputs.private_subnet_ids

  disk_size      = var.disk_size
  instance_types = [var.instance_type]
  labels = {
    role = var.node_role
  }

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  remote_access {
    ec2_ssh_key               = var.key_pair
    source_security_group_ids = var.allow_security_group_ids
  }

  tags = {
    "Name" = "${var.base_name}-${var.node_role}-node-group"
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

}