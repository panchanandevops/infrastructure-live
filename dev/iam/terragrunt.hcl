terraform {
  source = "git@github.com:panchanandevops/terraform-aws-iam.git//iam?ref=iam-v0.0.2"
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
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    eks_name = "dam"
  }
}

generate "helm_provider" {
  path      = "helm-provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
data "aws_caller_identity" "current" {}

provider "aws" {
  region  = "us-east-1"
}
EOF
}