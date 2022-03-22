base_name                 = "eks-test-shimadzu"
eks_version               = "1.21"
endpoint_private_access   = true
endpoint_public_access    = true
public_access_cidrs       = ["119.106.76.97/32"]
enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
retention_in_days         = 1
