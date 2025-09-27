include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  environment = "demo"
}

inputs = {
  environment = local.environment
  vpc_cidr    = "10.1.0.0/16"
  azs         = ["us-east-1a", "us-east-1b"]
  app_domain  = "demo.ruby-app.example.com"
}

terraform {
  source = "../../modules//vpc"
}

dependencies {
  paths = []
}