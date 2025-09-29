locals {
  aws_region = "us-east-1"
  
  # Get just the environment name (stage, demo, or prod) from the path
  environment = split("/", path_relative_to_include())[0]

  # Environment-specific configurations


  # Get configuration for current environment
 

  # Extract values for current environment
 
  
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
  
 
}
