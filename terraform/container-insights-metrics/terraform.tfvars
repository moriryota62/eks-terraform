base_name = "project-environment"
log_groups = {
  "performance" = {
    retention_in_days       = 1,
    transition_glacier_days = 1,
  },
}
# Cluster dimensions
cluster_dimensions = {
  "cluster-node-cpu-utilization" = {
    metric_name         = "node_cpu_utilization",
    comparison_operator = "GreaterThanOrEqualToThreshold",
    period              = "60",
    statistic           = "Average"
    threshold           = "50",
  },
  "cluster-node-memory-utilization" = {
    metric_name         = "node_memory_utilization",
    comparison_operator = "GreaterThanOrEqualToThreshold",
    period              = "60",
    statistic           = "Average"
    threshold           = "50",
  },
}

# Namespace dimensions
namespace_dimensions = {
  # "ns-default-number-of-pods" = {
  #   metric_name         = "namespace_number_of_running_pods",
  #   comparison_operator = "LessThanOrEqualToThreshold",
  #   period              = "60",
  #   statistic           = "Average"
  #   threshold           = "0",
  #   namespace           = "default",
  # },
}

# Service dimensions
service_dimensions = {
  "test-number-of-pods" = {
    metric_name         = "service_number_of_running_pods",
    comparison_operator = "LessThanOrEqualToThreshold",
    period              = "60",
    statistic           = "Average"
    threshold           = "0",
    namespace           = "default",
    service             = "test",
  },
}

# Pod dimensions
pod_dimensions = {
  "test-cpu-utilization" = {
    metric_name         = "pod_cpu_utilization_over_pod_limit",
    comparison_operator = "GreaterThanOrEqualToThreshold",
    period              = "60",
    statistic           = "Average"
    threshold           = "95",
    namespace           = "default",
    pod                 = "test",
  },
  "test-memory-utilization" = {
    metric_name         = "pod_memory_utilization_over_pod_limit",
    comparison_operator = "GreaterThanOrEqualToThreshold",
    period              = "60",
    statistic           = "Average"
    threshold           = "95",
    namespace           = "default",
    pod                 = "test",
  },
}
endpoint = ["moriryota62@gmail.com"]