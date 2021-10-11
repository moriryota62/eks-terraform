base_name = "project-environment"
log_groups = {
    "application" = { 
        retention_in_days = 1 ,
        transition_glacier_days = 1 ,
        filter_pattern = "?test ?error" ,
    },
    "dataplane" = { 
        retention_in_days = 1 ,
        transition_glacier_days = 1 ,
        filter_pattern = null ,
    },
    "host" = { 
        retention_in_days = 1 ,
        transition_glacier_days = 1 ,
        filter_pattern = null ,
    },
}
endpoint = ["moriryota62@gmail.com"]
