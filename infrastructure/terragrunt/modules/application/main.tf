terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.11.0"
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

variable "app_replicas" {
  description = "Number of application replicas"
  type        = number
  default     = 2
}

variable "app_domain" {
  description = "Domain name for the application"
  type        = string
}

resource "helm_release" "ruby_app" {
  name       = "ruby-app"
  chart      = "../../../helm/ruby-app"
  namespace  = var.environment
  create_namespace = true

  values = [
    jsonencode({
      replicaCount = var.app_replicas

      ingress = {
        enabled = true
        className = "nginx"
        hosts = [
          {
            host = var.app_domain
            paths = [
              {
                path = "/"
                pathType = "Prefix"
              }
            ]
          }
        ]
      }

      probes = {
        readiness = {
          enabled = true
          initialDelaySeconds = 10
          periodSeconds = 10
        }
        startup = {
          enabled = true
          initialDelaySeconds = 30
          periodSeconds = 10
        }
      }
    })
  ]
}