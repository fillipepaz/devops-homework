include "root" {
   path = find_in_parent_folders("root.hcl")
}

locals {
  environment = "stage"
}

terraform {
  source = "../../modules//kubernetes-components"
}

dependencies {
  paths = ["../02-eks"]
}

dependency "eks" {
  config_path = "../02-eks"

  mock_outputs = {
    cluster_name = "mock-cluster"
    cluster_endpoint = "https://mock-endpoint"
    cluster_certificate_authority_data = "mock-cert"
    cluster_auth_token = "mock-token"
  }
}

generate "providers" {
  path = "providers_override.tf"
  if_exists = "overwrite"
  contents = <<EOF
provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}
EOF
}

inputs = {
  environment = local.environment
  cluster_name = dependency.eks.outputs.cluster_name
}