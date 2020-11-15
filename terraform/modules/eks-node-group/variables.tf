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
variable "cluster_name" {
  description = "ノードグループを作成するEKSクラスタの名前"
  type        = string
}

variable "nodegroup_iam_arn" {
  description = "ノードグループに付与するiamロールのARN"
  type        = string
}

variable "private_subnet_ids" {
  description = "ノードグループが所属するプライベートサブネットのID"
  type        = list(string)
}

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
  default     = ""
}

variable "allow_security_group_ids" {
  description = "ノードにsshを許可するセキュリティグループ"
  type        = list(string)
  default     = []
}