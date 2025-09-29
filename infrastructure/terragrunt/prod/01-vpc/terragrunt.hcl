include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  environment = "prod"
  # Toggle between creating new VPC or using existing one
  create_vpc = true  
  
  # Existing VPC and subnet IDs (used when create_vpc = false)
  existing_vpc_config = {
    vpc_id           = "vpc-1234567890"  
    private_subnets  = ["subnet-private1", "subnet-private2"]  
    public_subnets   = ["subnet-public1", "subnet-public2"]    
  }
}

inputs = {
  environment = local.environment
  
  # VPC Creation Control
  create_vpc = local.create_vpc
  
  # New VPC Configuration (used when create_vpc = true)
  vpc_cidr    = "10.0.0.0/16"
  azs         = ["us-east-1a", "us-east-1b"]
  
  # Existing VPC Configuration (used when create_vpc = false)
  vpc_id           = local.create_vpc ? null : local.existing_vpc_config.vpc_id
  private_subnets  = local.create_vpc ? [] : local.existing_vpc_config.private_subnets
  public_subnets   = local.create_vpc ? [] : local.existing_vpc_config.public_subnets
}

terraform {
  source = "../../modules//vpc"
}