# common parameter
variable "base_name" {
  description = "作成するリソースに付与する接頭語"
  type        = string
}

# module parameter
variable "zone_name" {
  description = "ホストゾーンの名前"
  type        = string
}

variable "recods" {
  description = "登録するレコード情報"
  type = map(object({
    name        = string
    elb_name    = string
    elb_zone_id = string
  }))
  default = null
}