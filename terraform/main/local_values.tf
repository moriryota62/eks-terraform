terraform {
  required_version = ">= 0.13.5"
}

provider "aws" {
  version = ">= 3.5.0"
  region  = "us-east-2"
}

# parameter settings
locals {
  # common parameter
  pj        = "PJ"
  env       = "ENV"
  base_name = "${local.pj}-${local.env}"
  tags = {
    pj    = "PJ"
    env   = "ENV"
    owner = "OWNER"
  }

  # module parameter
  ## network
  network_vpc_cidr             = "10.1.0.0/16"
  network_subnet_public_cidrs  = ["10.1.10.0/24", "10.1.11.0/24"]
  network_subnet_private_cidrs = ["10.1.20.0/24", "10.1.21.0/24"]

  ## bastion
  bastion_ec2_instance_type          = "t2.medium"
  bastion_ec2_root_block_volume_size = 30
  bastion_ec2_key_name               = "mori"
  bastion_sg_allow_access_cidrs      = ["210.20.194.5/32"]
  bastion_cloudwatch_enable_schedule = true
  bastion_cloudwatch_start_schedule  = "cron(0 0 ? * MON-FRI *)"
  bastion_cloudwatch_stop_schedule   = "cron(0 10 ? * MON-FRI *)"

  ## efs
  ### 以下はEFSに/test1と/test2のアクセスポイントを作成する記述例です。
  ### EFS CSI Driverを使用してEKSからEFSを使用する場合はアクセスポイントを用途ごとに作成します。
  ### EFS provisionerを使用してEKSからEFSを使用する場合は`efs_access_points = {}`としてください。
  efs_access_points = {
//    "/test1" = {
//      path        = "/test1",
//      owner_gid   = 0,
//      owner_uid   = 0,
//      permissions = "0777"
//    },
//    "/test2" = {
//      path        = "/test2",
//      owner_gid   = 0,
//      owner_uid   = 0,
//      permissions = "0777"
//    }
  }

  ## eks
  eks_version                 = "1.18"
  eks_endpoint_private_access = true
  eks_endpoint_public_access  = true
  #  eks_public_access_cidrs     = ["210.20.194.5/32"] # Anyの場合0.0.0.0/0を指定する
  eks_public_access_cidrs = ["0.0.0.0/0"] # 空の場合0.0.0.0/0になる

  ## node group
  ### 複数種類のノードグループを作る場合、以下ブロックをコピペして変数名を変えてください。
  ### たとえばOpenShiftの様にインフラノードとアプリノードを分ける場合に上記のカスタマイズが必要です。
  node_disk_size     = 30
  node_instance_type = "t3.medium"
  node_node_role     = "worker"
  node_desired_size  = 1
  node_max_size      = 1
  node_min_size      = 1
  node_key_pair      = "mori"

  # fargate
  fargate_namespace_name = "default"
  fargate_labels         = { "worker" = "fargate" }

  # IAM for SA
  iamsa_k8s_namespace     = "default"
  iamsa_k8s_sa            = "iam-test"
  iamsa_attach_policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}
