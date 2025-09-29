include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  environment = "prod"
}

terraform {
  source = "../../modules//eks"
}

dependencies {
  paths = ["../01-vpc"]
}

dependency "vpc" {
  config_path = "../01-vpc"

  mock_outputs = {
    vpc_id = "vpc-12345"
    private_subnets = ["subnet-12345", "subnet-67890"]
  }
}

inputs = {
  environment = local.environment
  vpc_id = dependency.vpc.outputs.vpc_id
  private_subnets = dependency.vpc.outputs.private_subnets
 cluster_version = "1.33"
      instance_types  = ["t3.medium"]
      min_size       = 2
      max_size       = 4
      desired_size   = 2
}