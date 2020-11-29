output "efs_id" {
  value = aws_efs_file_system.this.id
}

output "access_point_id" {
  value = [
    for access_point in aws_efs_access_point.this :
    "${access_point.root_directory[0].path} = ${access_point.file_system_id}::${access_point.id}"
  ]
}