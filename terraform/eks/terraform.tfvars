base_name                 = "project-environment"
eks_version               = "1.21"
endpoint_private_access   = true
endpoint_public_access    = true
public_access_cidrs       = ["0.0.0.0/0"]
enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
retention_in_days         = 1
