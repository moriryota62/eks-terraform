# common parameter
variable "base_name" {
  description = "作成するリソースに付与する接頭語"
  type        = string
}

# module parameter
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