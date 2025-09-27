include "root" {
   path = find_in_parent_folders("root.hcl")
}

locals {
  environment = "stage"
}

terraform {
  source = "../../modules//application"
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

inputs = {
  environment = local.environment
  cluster_name = dependency.eks.outputs.cluster_name
  app_domain = "stage.ruby-app.example.com"
  app_replicas = 2
}
