# common parameter
variable "base_name" {
  description = "作成するリソースに付与する接頭語"
  type        = string
}

# module parameter
variable "eks_version" {
  description = "作成するEKSのバージョン"
  type        = string
}

variable "endpoint_private_access" {
  description = "VPC内からEKSのAPIサーバーへのアクセスを許可するか"
  type        = bool
}

variable "endpoint_public_access" {
  description = "VPC外からEKSのAPIサーバーへのアクセスを許可するか"
  type        = bool
}

variable "public_access_cidrs" {
  description = "VPC外からEKSのAPIサーバーへのアクセスを許可するCIDRリスト"
  type        = list(string)
}

variable "enabled_cluster_log_types" {
  description = "ログ収集を有効にするマスターコンポーネント"
  type        = list(string)
}
