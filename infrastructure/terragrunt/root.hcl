locals {
  aws_region = "us-east-1"
  
  # Get just the environment name (stage, demo, or prod) from the path
  environment = split("/", path_relative_to_include())[0]

  # Environment-specific configurations
  env_configs = {
    stage = {
      cluster_version = "1.33"
      instance_types  = ["t3.medium"]
      min_size       = 1
      max_size       = 3
      desired_size   = 1
    }
    demo = {
      cluster_version = "1.33"
      instance_types  = ["t3.medium"]
      min_size       = 2
      max_size       = 4
      desired_size   = 2
    }
    prod = {
      cluster_version = "1.33"
      instance_types  = ["t3.large"]
      min_size       = 3
      max_size       = 6
      desired_size   = 3
    }
  }

  # Get configuration for current environment
  env_config = local.env_configs[local.environment]

  # Extract values for current environment
  cluster_version = local.env_config.cluster_version
  instance_types  = local.env_config.instance_types
  min_size       = local.env_config.min_size
  max_size       = local.env_config.max_size
  desired_size   = local.env_config.desired_size
  
  # Common tags
  common_tags = {
    Environment = local.environment
    Project     = "ruby-app"
    ManagedBy   = "terragrunt"
  }
}

# Remote state configuration
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "terraform-state-${get_aws_account_id()}-${local.aws_region}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = "terraform-locks-${get_aws_account_id()}-${local.environment}"
  }
}

# Generate provider configuration
generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  
  contents = <<EOF
provider "aws" {
  region = "${local.aws_region}"
  default_tags {
    tags = ${jsonencode(local.common_tags)}
  }
}
EOF
}

# Global inputs available to all modules
inputs = {
  aws_region = local.aws_region
  environment = local.environment
  tags = local.common_tags
  cluster_version = local.cluster_version
  instance_types = local.instance_types
  min_size = local.min_size
  max_size = local.max_size
  desired_size = local.desired_size
}
