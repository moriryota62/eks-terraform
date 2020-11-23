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
  vpc_cidr             = "10.1.0.0/16"
  subnet_public_cidrs  = ["10.1.10.0/24", "10.1.11.0/24"]
  subnet_private_cidrs = ["10.1.20.0/24", "10.1.21.0/24"]

  ## bastion
  ec2_instance_type          = "t2.medium"
  ec2_root_block_volume_size = 30
  ec2_key_name               = "mori"
  sg_allow_access_cidrs      = ["210.20.194.5/32"]
  cloudwatch_enable_schedule = true
  cloudwatch_start_schedule  = "cron(0 0 ? * MON-FRI *)"
  cloudwatch_stop_schedule   = "cron(0 10 ? * MON-FRI *)"

  ## eks
  eks_version             = "1.18"
  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs     = ["210.20.194.5/32"] # 空の場合0.0.0.0/0になる

  ## node group
  ### 複数種類のノードグループを作る場合、以下ブロックをコピペして変数名を変えてください。
  ### たとえばOpenShiftの様にインフラノードとアプリノードを分ける場合に上記のカスタマイズが必要です。
  disk_size     = 30
  instance_type = "t3.medium"
  node_role     = "worker"
  desired_size  = 1
  max_size      = 1
  min_size      = 1
  key_pair      = "mori"

  # fargate
  namespace_name = "default"
  labels         = { "worker" = "fargate" }

  # IAM for SA
  k8s_namespace     = "default"
  k8s_sa            = "iam-test"
  attach_policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}
