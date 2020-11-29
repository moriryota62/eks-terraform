# common parameter
variable "tags" {
  description = "リソース群に付与する共通タグ"
  type        = map(string)
}

variable "base_name" {
  description = "作成するリソースに付与する接頭語"
  type        = string
}

# module parameter

variable "kms_id" {
  description = "暗号化に使用するKMSのARN"
  type        = string
}

variable "private_subnet_ids" {
  description = "EFSを接続するプライベートサブネットのIDリスト"
  type        = list(string)
}

variable "vpc_id" {
  description = "EFSへの接続を許可するVPCのID"
  type        = string
}

variable "vpc_cidr" {
  description = "EFSへの接続を許可するVPCのCIDR"
  type        = string
}

variable "access_points" {
  description = "アクセスポイントの設定 path=アクセスポイントにするパス(/から絶対パス) owner_gid=アクセスポイントのgid owner_uid=アクセスポイントのuid permissions=アクセスポイントのパーミッション"
  type = map(object({
    path        = string
    owner_gid   = number
    owner_uid   = number
    permissions = string
  }))
  default = {}
}