output "bastion_sg_id" {
  value = aws_security_group.bastion.id
}

output "bastion_eip" {
  value = aws_eip.bastion.public_ip
}