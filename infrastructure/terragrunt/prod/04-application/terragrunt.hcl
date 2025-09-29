include "root" {
   path = find_in_parent_folders("root.hcl")
}

locals {
  environment = "prod"
}



dependencies {
  paths = ["../03-kubernetes-components"]
}

dependency "eks" {
  config_path = "../02-eks"

  mock_outputs = {
    cluster_name = "mock-cluster"
  }
}

# Configure providers for Kubernetes and Helm
generate "providers" {
  path      = "providers.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.this.name]
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.this.name]
    }
  }
}


EOF
}

inputs = {
  environment = local.environment
  cluster_name = dependency.eks.outputs.cluster_name
  use_nlb_dns = true
  app_replicas = 2
  chart_path = "${get_repo_root()}/helm/ruby-app"
  image_tag = "06563a9905eb0a2d90ed5a0df64313d7bd789301"
}

terraform {
  source = "../../modules//application"
}
# Show application URL after successful apply


