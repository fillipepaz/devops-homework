



locals {
  name = "vpc-${var.environment}"
  
  # Only calculate subnet CIDRs if creating new VPC
  vpc_id = var.create_vpc ? module.vpc[0].vpc_id : var.vpc_id
  
  private_subnet_ids = var.create_vpc ? module.vpc[0].private_subnets : var.private_subnets
  public_subnet_ids  = var.create_vpc ? module.vpc[0].public_subnets : var.public_subnets
  
  # Calculate subnet CIDRs for new VPC - ensuring no overlap with larger subnets
  calculated_private_subnets = ["10.0.0.0/19", "10.0.32.0/19"]#[for k, v in var.azs : cidrsubnet(var.vpc_cidr, 3, k)]
  calculated_public_subnets  = ["10.0.128.0/19","10.0.160.0/19"]
  
  common_tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = var.project
    Name        = local.name
  }
}

# Create new VPC if create_vpc = true
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"  # Fixed version for better stability
  
  count = var.create_vpc ? 1 : 0

  name = local.name
  cidr = var.vpc_cidr

  azs             = var.azs
  private_subnets = local.calculated_private_subnets
  public_subnets  = local.calculated_public_subnets

  enable_nat_gateway     = true
  single_nat_gateway     = var.environment != "prod"
  enable_dns_hostnames   = true
  enable_dns_support     = true

  private_subnet_tags = merge(local.common_tags, {
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/eks-${var.environment}" = "shared"
    Tier = "Private"
  })

  public_subnet_tags = merge(local.common_tags, {
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/eks-${var.environment}" = "shared"
    Tier = "Public"
  })

  tags = local.common_tags
}



output "vpc_id" {
  value = local.vpc_id
}

output "private_subnets" {
  value = local.private_subnet_ids
}

output "public_subnets" {
  value = local.public_subnet_ids
}