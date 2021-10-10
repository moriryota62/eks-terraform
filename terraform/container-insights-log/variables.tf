# common parameter
variable "base_name" {
  description = "リソース群に付与する接頭語"
  type        = string
}

# module parameter
variable "log_groups" {
  description = "ロググループの一覧。ロググループごとにCloudWatchの保持期間を設定。また、Glacierへ以降する日数も設定"
  type = map(object({
    retention_in_days = number
    transition_glacier_days = number
  }))
}