base_name                  = "project-environment"
ec2_instance_type          = "t3.medium"
ec2_root_block_volume_size = 30
ec2_key_name               = "mori"
sg_allow_access_cidrs      = []
cloudwatch_enable_schedule = true
cloudwatch_start_schedule  = "cron(0 0 ? * MON-FRI *)"
cloudwatch_stop_schedule   = "cron(0 9 ? * MON-FRI *)"
