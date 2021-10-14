# common parameter
variable "base_name" {
  description = "リソース群に付与する接頭語"
  type        = string
}

# module parameter
variable "log_groups" {
  description = "ロググループの一覧。<br>retention_in_daysはCloudWatchの保持日数。<br>transition_glacier_daysはGlacierへ移行する日数。"
  type = map(object({
    retention_in_days       = number
    transition_glacier_days = number
  }))
}

variable "cluster_dimensions" {
  description = "通知するメトリクスの一覧。<br>metric_nameは通知対象のメトリクス名。<br>comparison_operatorは比較演算の種類。<br>periodは集計期間(秒)。<br>statisticは統計の種類。<br>thresholdはしきい値。<br>Clusterレベルのアラート通知を行わない場合、空マップを指定する。"
  type = map(object({
    metric_name         = string
    comparison_operator = string
    period              = string
    statistic           = string
    threshold           = string
  }))
}

variable "namespace_dimensions" {
  description = "通知するメトリクスの一覧。<br>metric_nameは通知対象のメトリクス名。<br>periodは集計期間(秒)。<br>statisticは統計の種類。<br>thresholdはしきい値。<br>namespaceは通知対象のNamespace名。<br>Namespaceレベルのアラート通知を行わない場合、空マップを指定する。"
  type = map(object({
    metric_name         = string
    comparison_operator = string
    period              = string
    statistic           = string
    threshold           = string
    namespace           = string
  }))
}

variable "service_dimensions" {
  description = "通知するメトリクスの一覧。<br>metric_nameは通知対象のメトリクス名。<br>periodは集計期間(秒)。<br>statisticは統計の種類。<br>thresholdはしきい値。<br>namespaceは通知対象のServiceが動くNamespace名。<br>Serviceは通知対象のPod名。<br>Serviceレベルのアラート通知を行わない場合、空マップを指定する。"
  type = map(object({
    metric_name         = string
    comparison_operator = string
    period              = string
    statistic           = string
    threshold           = string
    namespace           = string
    service             = string
  }))
}

variable "pod_dimensions" {
  description = "通知するメトリクスの一覧。<br>metric_nameは通知対象のメトリクス名。<br>periodは集計期間(秒)。<br>statisticは統計の種類。<br>thresholdはしきい値。<br>namespaceは通知対象のPodが動くNamespace名。<br>Podは通知対象のPod名。<br>Podレベルのアラート通知を行わない場合、空マップを指定する。"
  type = map(object({
    metric_name         = string
    comparison_operator = string
    period              = string
    statistic           = string
    threshold           = string
    namespace           = string
    pod                 = string
  }))
}

variable "endpoint" {
  description = "通知する先のメールアドレス"
  type        = list(string)
}
