locals {
  aws_region = "us-east-1"
  environment = path_relative_to_include()
  cluster_version = "1.30"
  instance_types  = ["t3.medium"]
  min_size       = 2
  max_size       = 4
  desired_size   = 3
  
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
    dynamodb_table = "terraform-locks-${get_aws_account_id()}"
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
