# common parameter
variable "base_name" {
  description = "作成するリソースに付与する接頭語"
  type        = string
}

# module parameter
variable "eks-fargate_profiles" {
  description = "Fargateプロファイルの設定。Fargateプロファイルを作成しない場合は空マップ「{}」にする。"
  type = map(object({
    namespace = string
    labels    = map(string)
  }))
}