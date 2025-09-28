include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  environment = "demo"
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
}