# common
base_name = "eks-test-shimadzu"

# cloudwatch
log_groups = {
  "application" = {
    retention_in_days       = 1,
    transition_glacier_days = 1,
    filter_pattern          = "?test ?error",
  },
  "dataplane" = {
    retention_in_days       = 1,
    transition_glacier_days = 1,
    filter_pattern          = null,
  },
  "host" = {
    retention_in_days       = 1,
    transition_glacier_days = 1,
    filter_pattern          = null,
  },
}

# SNS
endpoint = ["youraddress@email.com"]

# Lambda
log_group_lambda_retention_in_days = 1
