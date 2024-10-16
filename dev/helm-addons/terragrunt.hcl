terraform {
  source = "git@github.com:panchanandevops/terraform-aws-helm-addons.git//helm-addons?ref=helm-v0.0.2"
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
  env      = include.env.locals.env
  eks_name = dependency.eks.outputs.eks_name

  cluster_autoscaler = {
    enable              = true
    region              = "us-east-1"
    helm_chart_version  = "9.37.0"
    path_to_values_file = "${path.module}/values/cluster_autoscaler.yaml"
  }

  metrics_server = {
    enable              = true
    helm_chart_version  = "3.12.1"
    path_to_values_file = "${path.module}/values/metrics_server.yaml"
  }

  aws_lbc = {
    enable              = true
    helm_chart_version  = "1.7.2"
    path_to_values_file = "${path.module}/values/aws_lbc.yaml"
  }

  external_nginx_ingress_controller = {
    enable              = true
    helm_chart_version  = "4.10.1"
    path_to_values_file = "${path.module}/values/nginx_ingress_controller.yaml"
  }

}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    eks_name            = "demo"
  }
}

generate "helm_provider" {
  path      = "helm-provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF

data "aws_eks_cluster" "eks" {
    name = var.eks_name
}

data "aws_eks_cluster_auth" "eks" {
    name = var.eks_name
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}
EOF
}