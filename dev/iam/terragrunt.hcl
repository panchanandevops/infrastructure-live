terraform {
  source = "git@github.com:panchanandevops/terraform-aws-iam.git//iam?ref=iam-v0.0.4"
}

include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

inputs = {
  env         = include.env.locals.env
  eks_name    = dependency.eks.outputs.eks_name
  account_id  = get_aws_account_id()
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    eks_name = "dam"
  }
}
