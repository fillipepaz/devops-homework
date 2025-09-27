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

data "aws_iam_role" "lb_controller" {
  name = "lb-controller-eks-${var.environment}"
}

# Create RBAC resources for nginx-ingress
resource "kubernetes_cluster_role" "nginx_ingress" {
  metadata {
    name = "nginx-ingress-clusterrole"
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps", "endpoints", "nodes", "pods", "secrets", "services"]
    verbs      = ["list", "watch", "get"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingressclasses", "ingresses", "ingresses/status"]
    verbs      = ["get", "list", "watch", "update"]
  }

  rule {
    api_groups = ["discovery.k8s.io"]
    resources  = ["endpointslices"]
    verbs      = ["list", "watch", "get"]
  }
}

resource "kubernetes_cluster_role_binding" "nginx_ingress" {
  metadata {
    name = "nginx-ingress-clusterrole-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.nginx_ingress.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "nginx-ingress-ingress-nginx"
    namespace = "ingress-nginx"
  }
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
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
            "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
          }
        }
        serviceAccount = {
          annotations = {
            "eks.amazonaws.com/role-arn" = data.aws_iam_role.lb_controller.arn
          }
        }
        ingressClassResource = {
          default = true
        }
        admissionWebhooks = {
          enabled = true
          failurePolicy = "Ignore"  # Don't fail if webhook is unavailable
          timeoutSeconds = 30
        }
        config = {
          "enable-ssl-passthrough" = false
          "enable-ssl-redirect" = false
          "force-ssl-redirect" = false
          "ssl-redirect" = false
          "allow-snippet-annotations" = true
          "use-forwarded-headers" = true
          "server-snippet" = "proxy_ssl_verify off;"
        }
        extraArgs = {
          "allow-snippet-annotations" = true
          "default-ssl-certificate" = "ingress-nginx/default-certificate"
        }
      }
    })
  ]

  depends_on = [
    kubernetes_cluster_role.nginx_ingress,
    kubernetes_cluster_role_binding.nginx_ingress
  ]
}