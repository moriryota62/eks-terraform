# common parameter
variable "base_name" {
  description = "作成するリソースに付与する接頭語"
  type        = string
}

# module parameter
variable "disk_size" {
  description = "ノードのローカルディスク容量"
  type        = number
}

variable "instance_type" {
  description = "ノードのインスタンスタイプ"
  type        = string
}

variable "node_role" {
  description = "ノードグループの役割"
  type        = string
}

variable "desired_size" {
  description = "ノードの希望数"
  type        = number
}

variable "max_size" {
  description = "ノードの最大数"
  type        = number
}

variable "min_size" {
  description = "ノードの最小数"
  type        = number
}

variable "key_pair" {
  description = "ノードにsshするkeyペア"
  type        = string
}

variable "allow_security_group_ids" {
  description = "ノードにsshを許可するセキュリティグループ"
  type        = list(string)
}