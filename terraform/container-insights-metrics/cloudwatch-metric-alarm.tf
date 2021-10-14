resource "aws_cloudwatch_metric_alarm" "cluster_dimensions" {
  for_each = var.cluster_dimensions != {} ? var.cluster_dimensions : {}

  alarm_name          = "${var.base_name}-${each.key}"
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = "1"
  metric_name         = each.value.metric_name
  namespace           = "ContainerInsights"
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_description   = "alarm container insights metrics"
  alarm_actions       = [aws_sns_topic.metrics.arn]
  dimensions = {
    ClusterName = data.terraform_remote_state.eks.outputs.cluster_name,
  }

  tags = {
    "Name" = "${var.base_name}-${each.key}"
  }
}

resource "aws_cloudwatch_metric_alarm" "namespace_dimensions" {
  for_each = var.namespace_dimensions != {} ? var.namespace_dimensions : {}

  alarm_name          = "${var.base_name}-${each.key}"
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = "1"
  metric_name         = each.value.metric_name
  namespace           = "ContainerInsights"
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_description   = "alarm container insights metrics"
  alarm_actions       = [aws_sns_topic.metrics.arn]
  dimensions = {
    ClusterName = data.terraform_remote_state.eks.outputs.cluster_name,
    Namespace   = each.value.namespace,
  }

  tags = {
    "Name" = "${var.base_name}-${each.key}"
  }
}

resource "aws_cloudwatch_metric_alarm" "service_dimensions" {
  for_each = var.service_dimensions != {} ? var.service_dimensions : {}

  alarm_name          = "${var.base_name}-${each.key}"
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = "1"
  metric_name         = each.value.metric_name
  namespace           = "ContainerInsights"
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_description   = "alarm container insights metrics"
  alarm_actions       = [aws_sns_topic.metrics.arn]
  dimensions = {
    ClusterName = data.terraform_remote_state.eks.outputs.cluster_name,
    Namespace   = each.value.namespace,
    Service     = each.value.service,
  }

  tags = {
    "Name" = "${var.base_name}-${each.key}"
  }
}

resource "aws_cloudwatch_metric_alarm" "pod_dimensions" {
  for_each = var.pod_dimensions != {} ? var.pod_dimensions : {}

  alarm_name          = "${var.base_name}-${each.key}"
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = "1"
  metric_name         = each.value.metric_name
  namespace           = "ContainerInsights"
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_description   = "alarm container insights metrics"
  alarm_actions       = [aws_sns_topic.metrics.arn]
  dimensions = {
    ClusterName = data.terraform_remote_state.eks.outputs.cluster_name,
    Namespace   = each.value.namespace,
    PodName     = each.value.pod,
  }

  tags = {
    "Name" = "${var.base_name}-${each.key}"
  }
}