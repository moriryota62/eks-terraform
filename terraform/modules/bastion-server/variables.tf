# common parameter
variable "tags" {
  description = "リソース群に付与する共通タグ"
  type        = map(string)
}

variable "base_name" {
  description = "リソース群に付与する接頭語"
  type        = string
}

# module parameter
variable "vpc_id" {
  description = "リソース群が属するVPCのID"
  type        = string
}

variable "ec2_instance_type" {
  description = "踏み台サーバーのインスタンスタイプ"
  type        = string
}

variable "ec2_subnet_id" {
  description = "踏み台サーバーを配置するパブリックサブネットのID"
  type        = string
}

variable "ec2_root_block_volume_size" {
  description = "踏み台サーバーのルートデバイスの容量(GB)"
  type        = number
}

variable "ec2_key_name" {
  description = "踏み台サーバーのインスタンスにsshログインするためのキーペア名"
  type        = string
  default     = null
}

variable "sg_allow_access_cidrs" {
  description = "踏み台サーバーへのアクセスを許可するCIDRリスト"
  type        = list(string)
}

variable "cloudwatch_enable_schedule" {
  description = "踏み台サーバーを自動起動/停止するか"
  type        = bool
  default     = false
}

variable "cloudwatch_start_schedule" {
  description = "踏み台サーバーを自動起動する時間。時間の指定はUTCのため注意"
  type        = string
  default     = "cron(0 0 ? * MON-FRI *)"
}

variable "cloudwatch_stop_schedule" {
  description = "踏み台サーバーを自動停止する時間。時間の指定はUTCのため注意"
  type        = string
  default     = "cron(0 10 ? * MON-FRI *)"
}
