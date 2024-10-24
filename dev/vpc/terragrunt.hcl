terraform {
  source = "git@github.com:panchanandevops/terrafrom-aws-vpc.git//vpc?ref=vpc-v0.0.1"
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
  env = include.env.locals.env

  private_subnets = {
    "10.0.0.0/19"  = "us-east-1a"
    "10.0.32.0/19" = "us-east-1b"
  }

  public_subnets = {
    "10.0.64.0/19"  = "us-east-1a"
    "10.0.96.0/19"  = "us-east-1b"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "kubernetes.io/cluster/dev-demo"  = "owned"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb"         = 1
    "kubernetes.io/cluster/dev-demo" = "owned"
  }
}