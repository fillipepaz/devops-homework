include "root" {
   path = find_in_parent_folders("root.hcl")
}

locals {
  environment = "prod"
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

# Configure providers for Kubernetes and Helm
generate "providers" {
  path      = "providers.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "kubernetes" {
  host                   = "${dependency.eks.outputs.cluster_endpoint}"
  cluster_ca_certificate = base64decode("${dependency.eks.outputs.cluster_certificate_authority_data}")
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", "${dependency.eks.outputs.cluster_name}"]
  }
}

provider "helm" {
  kubernetes {
    host                   = "${dependency.eks.outputs.cluster_endpoint}"
    cluster_ca_certificate = base64decode("${dependency.eks.outputs.cluster_certificate_authority_data}")
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", "${dependency.eks.outputs.cluster_name}"]
    }
  }
}
EOF
}

inputs = {
  environment = local.environment
  cluster_name = dependency.eks.outputs.cluster_name
}