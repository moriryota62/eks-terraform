# common parameter
variable "base_name" {
  description = "作成するリソースに付与する接頭語"
  type        = string
}

# module parameter
variable "role_name" {
  description = "IAMロール名"
  type        = string
}

variable "k8s_namespace" {
  description = "iamと紐付けるk8sのSAが属するNamespace"
  type        = string
}

variable "k8s_sa" {
  description = "iamと紐付けるk8sのSA"
  type        = string
}
