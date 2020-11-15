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
  labels         = { "fargate" = "yes" }
}

# VPC、サブネット、インターネットゲートウェイ、NATゲートウェイ、ECRのプライベートリンクを作成するモジュールです。
# 既存のVPCを使う場合はこのモジュール部分をコメントアウトしてください。
# その場合、後述するモジュール内で「module.network~」でしている値を自身の環境の値に修正してください。
module "network" {
  source = "../modules/network"

  # common parameter
  tags      = local.tags
  base_name = local.base_name

  # module parameter
  vpc_cidr             = local.vpc_cidr
  subnet_public_cidrs  = local.subnet_public_cidrs
  subnet_private_cidrs = local.subnet_private_cidrs
}

# 踏み台サーバーを作成するモジュールです。
# EIPを割り当ててIPアドレスを固定化します。
# 最新のAmazonLinuxのAMIを使用し、指定したインスタンスタイプ、ディスクサイズでEC2インスタンスを作成します。
# 任意のCIDRからのSSHできるように設定できます。
# 起動/停止の自動スケジュールを任意に設定可能です。
module "bastion" {
  source = "../modules/bastion-server"

  # common parameter
  tags      = local.tags
  base_name = local.base_name

  # module parameter
  vpc_id                     = module.network.vpc_id
  ec2_instance_type          = local.ec2_instance_type
  ec2_subnet_id              = module.network.public_subnet_ids[0]
  ec2_root_block_volume_size = local.ec2_root_block_volume_size
  ec2_key_name               = local.ec2_key_name
  sg_allow_access_cidrs      = local.sg_allow_access_cidrs
  cloudwatch_enable_schedule = local.cloudwatch_enable_schedule
  cloudwatch_start_schedule  = local.cloudwatch_start_schedule
  cloudwatch_stop_schedule   = local.cloudwatch_stop_schedule
}

# EKS内のSecretリソースやEFSの暗号化に使用するCMKを作成するモジュールです。
# 既存のCMKを使用する場合はこのモジュールをコメントアウトしてください。
# その場合、後述するモジュール内で「module.kms~」でしている値を自身の環境の値に修正してください。
module "kms" {
  source = "../modules/kms"

  # common parameter
  tags      = local.tags
  base_name = local.base_name
}

# EFSを作成するモジュールです。
# EFSを使用しない場合や既存のEFSを使用する場合はこのモジュールをコメントアウトしてください。
module "efs" {
  source = "../modules/efs"

  # common parameter
  tags      = local.tags
  base_name = local.base_name

  # module parameter
  kms_id             = module.kms.kms_arn
  private_subnet_ids = module.network.private_subnet_ids
  vpc_id             = module.network.vpc_id
  vpc_cidr           = module.network.vpc_cidr
}

# EKSを作成するモジュールです。
# マスターコンポーネントのログはすべて有効に設定します。
# APIサーバーへのアクセス制御を任意に設定できます。
# EKS内のSecretは指定のCMKで暗号化されます。
module "eks" {
  source = "../modules/eks"

  # common parameter
  tags      = local.tags
  base_name = local.base_name

  # module parameter
  eks_version             = local.eks_version
  endpoint_private_access = local.endpoint_private_access
  endpoint_public_access  = local.endpoint_public_access
  public_access_cidrs     = local.public_access_cidrs
  public_subnet_ids       = module.network.public_subnet_ids
  private_subnet_ids      = module.network.private_subnet_ids
  kms_arn                 = module.kms.kms_arn
}

# EKSのマネージドワーカーノードを作成するモジュールです。
# 複数種類のワーカーノードを使う場合、以下モジュールブロックをコピペしてモジュール名や変数名を変えてください。
# たとえばOpenShiftの様にインフラノードとアプリノードを分ける場合に上記のカスタマイズが必要です。
# ワーカーノードのAMIは最新のEKS最適化AMIが使用されます。
# デフォルトではt3.medium、20GBのローカルボリュームを持つEC2インスタンスが作成されます。
# sshのアクセス設定も任意に可能です。
module "worker-node" {
  source = "../modules/eks-node-group"

  # common parameter
  tags      = local.tags
  base_name = local.base_name

  # module parameter
  cluster_name             = module.eks.cluster_name
  nodegroup_iam_arn        = module.eks.nodegroup_iam_arn
  private_subnet_ids       = module.network.private_subnet_ids
  disk_size                = local.disk_size
  instance_type            = local.instance_type
  node_role                = local.node_role
  desired_size             = local.desired_size
  max_size                 = local.max_size
  min_size                 = local.min_size
  key_pair                 = local.key_pair
  allow_security_group_ids = [module.bastion.bastion_sg_id]
}

# Fargateプロファイルを作成するモジュールです。
# Fargateを使用しない場合はこのモジュール部分をコメントアウトしてください。
# Fargateを起動できるNamespace、labelを指定できます。
module "fargate" {
  source = "../modules/eks-fargate"

  # common parameter
  tags      = local.tags
  base_name = local.base_name

  # module parameter
  cluster_name       = module.eks.cluster_name
  fargate_iam_arn    = module.eks.fargate_iam_arn
  private_subnet_ids = module.network.private_subnet_ids
  namespace_name     = local.namespace_name
  labels             = local.labels
}