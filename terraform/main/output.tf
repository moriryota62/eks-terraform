#output "bastion_eip" {
#  value = module.bastion.bastion_eip
#}
#
#output "efs_id" {
#  value = module.efs.efs_id
#}
#
#output "access_points" {
#  value = module.efs.access_point_id
#}

output "network" {
  value = module.network
}

output "alb_iam_role" {
  value = module.alb-iam-for-sa
}

output "iam_role" {
  value = module.iam-for-sa
}