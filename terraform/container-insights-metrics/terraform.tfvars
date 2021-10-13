base_name = "project-environment"
log_groups = {
    "performance" = { 
        retention_in_days = 1 ,
        transition_glacier_days = 1 ,
    },
}