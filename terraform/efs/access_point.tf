resource "aws_efs_access_point" "this" {
  for_each = var.access_points

  file_system_id = aws_efs_file_system.this.id

  root_directory {
    path = each.value.path

    creation_info {
      owner_gid   = each.value.owner_gid
      owner_uid   = each.value.owner_uid
      permissions = each.value.permissions
    }
  }
}
