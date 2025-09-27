terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.11.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.23.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.17.0"
    }
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "nginx_ingress_version" {
  description = "Version of nginx-ingress helm chart"
  type        = string
  default     = "4.7.1"  
}

resource "helm_release" "nginx_ingress" {
  name             = "nginx-ingress"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = var.nginx_ingress_version
  namespace        = "ingress-nginx"
  create_namespace = true

  values = [
    jsonencode({
      controller = {
        service = {
          type = "LoadBalancer"
        }
        ingressClassResource = {
          default = true
        }
      }
    })
  ]
}