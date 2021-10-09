base_name = "project-environment"
eks-fargate_profiles = {
  "namespace-select" = { namespace = "test", labels = {} },
  "label-select"     = { namespace = "default", labels = { "deploy" = "fargate" } }
}