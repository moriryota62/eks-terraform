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
variable "zone_name" {
  description = "ホストゾーンの名前"
  type        = string
}

variable "vpc_id" {
  description = "ホストゾーンを紐付けるVPCのID"
  type        = string
}

variable "recode" {
  description = "登録するレコード情報"
  type = map(object({
    name    = string
    records = list(string)
  }))
}