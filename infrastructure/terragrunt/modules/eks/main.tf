terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.19.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.23.0"
    }
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnets" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "instance_types" {
  description = "Instance types for node groups"
  type        = list(string)
}

variable "min_size" {
  description = "Minimum size of node group"
  type        = number
}

variable "max_size" {
  description = "Maximum size of node group"
  type        = number
}

variable "desired_size" {
  description = "Desired size of node group"
  type        = number
}

locals {
  name = "ruby-app-${var.environment}"
}

locals {
  eks_addon_vpc_cni_version     = "v1.15.0-eksbuild.2"
  eks_addon_ebs_csi_version     = "v1.23.0-eksbuild.1"
}

# Create IAM role for EBS CSI Driver
module "ebs_csi_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.30.0"

  role_name = "ebs-csi-controller-${local.name}"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.16.0"

  cluster_name    = local.name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  # Networking
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false

  # Enable EKS Add-ons
  cluster_addons = {
    vpc-cni = {
      most_recent = false
      version     = local.eks_addon_vpc_cni_version
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          ENABLE_POD_ENI          = "true"
        }
      })
    }
    aws-ebs-csi-driver = {
      most_recent = false
      version     = local.eks_addon_ebs_csi_version
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
  }

  eks_managed_node_groups = {
    default = {
      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_size

      instance_types = var.instance_types
      capacity_type  = "ON_DEMAND"

      labels = {
        Environment = var.environment
      }

      # Enable IMDSv2
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
      }

      # Enable EBS encryption
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            encrypted             = true
            delete_on_termination = true
            volume_size          = 50
            volume_type          = "gp3"
          }
        }
      }
    }
  }

  # Enable OIDC provider for service accounts
  enable_irsa = true

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

output "cluster_name" {
  value = module.eks.cluster_name
  description = "The name of the EKS cluster"
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
  description = "The endpoint of the EKS cluster"
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
  description = "The certificate authority data for the EKS cluster"
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
  description = "The ARN of the OIDC Provider for IRSA"
}

output "cluster_addons" {
  value = module.eks.cluster_addons
  description = "The status of EKS add-ons"
}

output "node_security_group_id" {
  value = module.eks.node_security_group_id
  description = "Security group ID for the node group"
}