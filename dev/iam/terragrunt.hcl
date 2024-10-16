terraform {
  source = "git@github.com:panchanandevops/terraform-aws-iam.git//iam?ref=iam-v0.0.3"
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
  account_id  = local.account_id
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    eks_name = "dam"
  }
}


data "aws_caller_identity" "current" {}

# Define local variables
locals {
  account_id  = data.aws_caller_identity.current.account_id  
}