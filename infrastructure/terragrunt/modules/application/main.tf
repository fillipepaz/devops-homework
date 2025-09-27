# Get EKS cluster data
data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.11"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.17"
    }
  }
}

resource "helm_release" "ruby_app" {
  name             = "${var.release_name}-${var.environment}"
  chart            = var.chart_path
  namespace        = var.environment
  create_namespace = var.create_namespace
  
  force_update  = true   # Force resource update through delete/recreate if needed
  atomic        = true   # If set, upgrade process rolls back changes made in case of failed upgrade
  cleanup_on_fail = true # Remove new resources created in this upgrade if upgrade fails
  wait         = true   # Wait until all resources are in ready state

  values = [
    jsonencode({
      replicaCount = var.app_replicas
      image = {
        repository = var.image_repository
        tag        = var.image_tag
        pullPolicy = var.image_pull_policy
      }
      ingress = {
        enabled = var.ingress_enabled
        className = var.ingress_class_name
        hosts = [
          {
            host = var.app_domain
            paths = [
              {
                path = var.ingress_path
                pathType = var.ingress_path_type
              }
            ]
          }
        ]
      }

      probes = {
        readiness = {
          enabled = var.readiness_probe_enabled
          initialDelaySeconds = var.readiness_probe_initial_delay
          periodSeconds = var.readiness_probe_period
        }
        startup = {
          enabled = var.startup_probe_enabled
          initialDelaySeconds = var.startup_probe_initial_delay
          periodSeconds = var.startup_probe_period
        }
        hpa = {
          enabled = var.hpa_enabled
          minReplicas = var.hpa_min_replicas
          maxReplicas = var.hpa_max_replicas
          targetCPUUtilizationPercentage = var.hpa_target_cpu_utilization_percentage
        }
      }
    })
  ]
}