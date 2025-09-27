include "root" {
  path = find_in_parent_folders()
}

locals {
  environment = "prod"
}

inputs = {
  environment = local.environment
  vpc_cidr    = "10.2.0.0/16"
  azs         = ["us-east-1a", "us-east-1b", "us-east-1c"]
  app_domain  = "ruby-app.example.com"
}

terraform {
  source = "../../modules//vpc"
}

dependencies {
  paths = []
}