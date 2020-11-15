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
  description = "fargateを紐付けるEKSクラスタの名前"
  type        = string
}

variable "fargate_iam_arn" {
  description = "fargateに付与するiamロールのARN"
  type        = string
}

variable "private_subnet_ids" {
  description = "fargateが所属するプライベートサブネットのID"
  type        = list(string)
}

variable "namespace_name" {
  description = "fargateを使用できるK8sのNamespace"
  type        = string
}

variable "labels" {
  description = "fargateを使用できるK8sのNamespace"
  type        = map(string)
}
