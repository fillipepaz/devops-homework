



locals {
  name = "eks-${var.environment}"
  eks_addon_vpc_cni_version     = "v1.15.0-eksbuild.2"
  eks_addon_ebs_csi_version     = "v1.23.0-eksbuild.1"
}

# Create IAM role for Load Balancer Controller
module "lb_controller_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.30.0"

  role_name = "lb-controller-${local.name}"
  
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = ["ingress-nginx:nginx-ingress-ingress-nginx"]
    }
  }
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
  cluster_endpoint_public_access  = var.api_server_public_access

  # Enable EKS Add-ons
  cluster_addons = {
    vpc-cni = {
      most_recent = false
      version     = local.eks_addon_vpc_cni_version
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = tostring(var.enable_prefix_delegation)
          ENABLE_POD_ENI          = tostring(var.enable_pod_eni)
        }
      })
    }
    aws-ebs-csi-driver = {
      most_recent = false
      version     = local.eks_addon_ebs_csi_version
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
  }

  # IAM role for nginx ingress controller
  cluster_security_group_additional_rules = {
    ingress_nginx_admission_webhook = {
      description = "Cluster API to Node group for nginx ingress webhook"
      protocol    = "tcp"
      from_port   = 8443
      to_port     = 8443
      type        = "ingress"
      self        = true
    }
  }

  eks_managed_node_groups = {
    default = {
      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_size

      instance_types = var.instance_types
      capacity_type  = var.capacity_type

      labels = {
        Environment = var.environment
      }

      # Add IAM policies for Ingress Controller
      iam_role_additional_policies = {
        AWSLoadBalancerController = "arn:aws:iam::aws:policy/service-role/AWSLoadBalancerControllerIAMPolicy"
        EC2NetworkingFullAccess   = "arn:aws:iam::aws:policy/AmazonEC2NetworkingFullAccess"
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
            volume_size          = var.volume_size
            volume_type          = var.volume_type
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

