# common parameter
variable "base_name" {
  description = "リソース群に付与する接頭語"
  type        = string
}

# module parameter
variable "log_groups" {
  description = "ロググループの一覧。<br>retention_in_daysはCloudWatchの保持日数。<br>transition_glacier_daysはGlacierへ移行する日数。<br>filter_patternはログ通知のトリガにする文字列。<br>通知が不要な場合filter_patternにnullを設定する。"
  type = map(object({
    retention_in_days       = number
    transition_glacier_days = number
    filter_pattern          = string
  }))
}

variable "endpoint" {
  description = "通知する先のメールアドレス"
  type        = list(string)
}
