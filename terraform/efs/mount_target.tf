resource "aws_efs_mount_target" "private_subnet" {
  count = length(data.terraform_remote_state.network.outputs.private_subnet_ids)

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = data.terraform_remote_state.network.outputs.private_subnet_ids[count.index]
  security_groups = [aws_security_group.allow_efs.id]
}