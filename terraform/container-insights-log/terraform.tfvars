base_name = "project-environment"
log_groups = {
    "application" = { 
        retention_in_days = 1 ,
        transition_glacier_days = 1 ,
    },
    "dataplane" = { 
        retention_in_days = 1 ,
        transition_glacier_days = 1 ,
    },
    "host" = { 
        retention_in_days = 1 ,
        transition_glacier_days = 1 ,
    },
}
