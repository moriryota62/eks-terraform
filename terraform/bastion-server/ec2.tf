locals {
  default_init_script = <<SHELLSCRIPT
#!/bin/bash

## install Docker
amazon-linux-extras install docker
systemctl enable docker
systemctl start docker

## install kubectl
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl
    SHELLSCRIPT
}

data "aws_ami" "recent_amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.recent_amazon_linux_2.image_id
  instance_type          = var.ec2_instance_type
  iam_instance_profile   = aws_iam_instance_profile.bastion.name
  subnet_id              = data.terraform_remote_state.network.outputs.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.bastion.id]
  user_data              = local.default_init_script

  tags = {
    "Name" = "${var.base_name}-bastion"
  }

  root_block_device {
    volume_size = var.ec2_root_block_volume_size
  }

  key_name = var.ec2_key_name

  lifecycle {
    ignore_changes = [ami]
  }
}

