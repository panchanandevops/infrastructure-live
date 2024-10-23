

# Infrastructure Setup with Terragrunt and Terraform

This repository contains the infrastructure-as-code (IaC) for deploying and managing a Kubernetes-based environment, utilizing AWS EKS, VPC, IAM roles, and various Helm-based Kubernetes addons. This setup leverages **Terragrunt** for managing Terraform configurations, promoting DRY (Don't Repeat Yourself) principles and ensuring easier reusability and maintainability of the code across environments.



This infrastructure uses **Terragrunt** to simplify Terraform management by handling remote state management, locking, and reusing configurations. The primary components of this repository include:

- **Amazon EKS** for Kubernetes orchestration.
- **VPC** with public and private subnets to host the infrastructure securely.
- **IAM** roles and policies required for the EKS nodes and other components.
- Various **Helm Addons** to extend Kubernetes functionality, including:
  - AWS Load Balancer Controller
  - Cluster Autoscaler
  - Metrics Server
  - External NGINX Ingress Controller

The infrastructure is defined for the `dev` environment, but the structure can easily be extended to other environments by following the same pattern.

## Pre-requisites

To deploy this infrastructure, ensure you have the following:

1. **AWS CLI** installed and configured with sufficient permissions to manage the required AWS resources.
2. **Terraform** and **Terragrunt** installed.
3. **Helm** installed for deploying Kubernetes Helm charts.
4. **kubectl** installed for managing your Kubernetes cluster.

You can install the tools using the following commands:

```bash
# Install Terraform
brew install terraform

# Install Terragrunt
brew install terragrunt

# Install Helm
brew install helm

# Install kubectl
brew install kubectl
```

---

## Terragrunt Configuration Overview

Each infrastructure component is managed through a `terragrunt.hcl` file, which defines the source of the Terraform module, how the module is integrated, and how different components depend on each other.

- **Environment-specific configuration** is managed via `env.hcl`.
- **Terragrunt Dependencies**: Resources like EKS, VPC, and IAM are configured to have dependencies on each other. For example, the EKS module relies on the VPC configuration.


## Environment Variables

To customize configurations per environment (like `dev`, `prod`), you can modify values in the `env.hcl` file:

```hcl
locals {
  env = "dev"
}
```

This file is crucial for specifying environment-wide variables like `env`, which are reused across the modules.

---

## Modules

This section provides an overview of the primary modules used in this infrastructure setup.



### 1. VPC Module Inputs

| **Input Key**        | **Description**                                                                                     | **Example Value**                                        |
|----------------------|-----------------------------------------------------------------------------------------------------|----------------------------------------------------------|
| `private_subnets`     | Defines the private subnets in the VPC. These subnets are used for internal resources, like EKS nodes.| `"10.0.0.0/19" = "us-east-1a", "10.0.32.0/19" = "us-east-1b"` |
| `public_subnets`      | Defines the public subnets in the VPC. These subnets are used for internet-facing resources.          | `"10.0.64.0/19" = "us-east-1a", "10.0.96.0/19" = "us-east-1b"` |
| `private_subnet_tags` | Tags for the private subnets to help manage internal resources.                                       | `"kubernetes.io/role/internal-elb" = 1`                   |
| `public_subnet_tags`  | Tags for the public subnets for managing resources like load balancers.                              | `"kubernetes.io/role/elb" = 1`                            |

---

### 2. EKS Module Inputs

| **Input Key**                            | **Description**                                                                                     | **Example Value**                                        |
|------------------------------------------|-----------------------------------------------------------------------------------------------------|----------------------------------------------------------|
| `eks_version`                            | Specifies the version of Amazon EKS to deploy.                                                       | `"1.29"`                                                 |
| `eks_name`                               | Defines the name of the Amazon EKS cluster.                                                          | `"demo"`                                                 |
| `node_groups.general.capacity_type`      | Specifies whether the nodes are `ON_DEMAND` or `SPOT` instances.                                     | `"ON_DEMAND"`                                            |
| `node_groups.general.instance_types`     | Defines the instance types for EKS nodes.                                                            | `["t3.small"]`                                           |
| `node_groups.general.scaling_config`     | Specifies the auto-scaling configuration for the EKS node group, including `desired_size`, `max_size`, and `min_size`. | `{ desired_size = 1, max_size = 10, min_size = 0 }`       |
| `node_iam_policies`                      | Specifies the IAM policies required by the EKS worker nodes.                                          | `"AmazonEKSWorkerNodePolicy"`, `"AmazonEKS_CNI_Policy"`   |
| `private_subnet_ids`                     | Private subnet IDs for launching EKS worker nodes.                                                    | `["subnet-1234", "subnet-5678"]`                         |

---

### 3. IAM Module Inputs

| **Input Key**        | **Description**                                                                                     | **Example Value**                                        |
|----------------------|-----------------------------------------------------------------------------------------------------|----------------------------------------------------------|
| `eks_name`           | Defines the name of the Amazon EKS cluster for IAM policies.                                         | `dependency.eks.outputs.eks_name`                        |
| `account_id`         | Retrieves the AWS account ID where the resources are deployed.                                       | `get_aws_account_id()`                                   |

---

### 4. Helm Addons Module Inputs

| **Input Key**                            | **Description**                                                                                     | **Example Value**                                        |
|------------------------------------------|-----------------------------------------------------------------------------------------------------|----------------------------------------------------------|
| `cluster_autoscaler.enable`              | Enables the Kubernetes Cluster Autoscaler.                                                           | `true`                                                   |
| `metrics_server.enable`                  | Enables the Kubernetes Metrics Server for resource metrics collection.                               | `true`                                                   |
| `aws_lbc.enable`                         | Enables the AWS Load Balancer Controller for managing Elastic Load Balancers in Kubernetes.           | `true`                                                   |
| `external_nginx_ingress_controller.enable`| Enables the NGINX Ingress Controller for handling external traffic to services within the cluster.    | `true`                                                   |
| `cluster_autoscaler.helm_chart_version`  | Specifies the Helm chart version for the Cluster Autoscaler.                                          | `"9.37.0"`                                               |
| `aws_lbc.path_to_policy_file`            | Defines the path to the JSON policy file for AWS Load Balancer Controller.                            | `"policy/AWSLoadBalancerController.json"`                 |
| `metrics_server.path_to_values_file`     | Specifies the path to the values YAML file for the Metrics Server Helm chart.                         | `"values/metrics_server.yaml"`                            |



---

## S3 Backend and Remote State

Terragrunt is configured to store the Terraform state in an S3 bucket for persistent, remote state management, along with a DynamoDB table for state locking.

Example configuration in the root `terragrunt.hcl`:

```hcl
remote_state {
  backend = "s3"
  config = {
    bucket         = "panchanandevops-tf-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock-table"
  }
}
```

This configuration ensures that the state is stored in the `panchanandevops-tf-state` bucket and is locked using DynamoDB to prevent multiple operations on the state at once.

---

## Helm Addons Details

The following table provides an overview of the Helm-based addons deployed through this infrastructure:

| Addon Name                  | Helm Chart Version | Enabled | Values File                            |
|-----------------------------|--------------------|---------|----------------------------------------|
| AWS Load Balancer Controller | 1.7.2              | Yes     | `values/aws_lbc.yaml`                  |
| Cluster Autoscaler           | 9.37.0             | Yes     | `values/cluster_autoscaler.yaml`       |
| Metrics Server               | 3.12.1             | Yes     | `values/metrics_server.yaml`           |
| NGINX Ingress Controller      | 4.10.1             | Yes     | `values/nginx_ingress_controller.yaml` |

---



## How to Deploy

### Initialize Environment

First, initialize the environment by running:

```bash
terragrunt run-all init
```



### Run Terraform Commands

To plan the infrastructure changes:

```bash
terragrunt run-all plan
```

To apply the infrastructure changes:

```bash
terragrunt run-all apply
```

