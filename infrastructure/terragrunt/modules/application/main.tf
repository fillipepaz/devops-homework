

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

# Get EKS cluster data
data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

# Get the LoadBalancer DNS name
data "kubernetes_service" "ingress_nginx" {
  metadata {
    name      = "nginx-ingress-ingress-nginx-controller"
    namespace = "ingress-nginx"
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
        #annotations = {
        #  "nginx.ingress.kubernetes.io/configuration-snippet" = "proxy_set_header Host $host;"
        #}
        hosts = [
          {
            host = var.use_nlb_dns ? data.kubernetes_service.ingress_nginx.status.0.load_balancer.0.ingress.0.hostname : var.app_domain
            paths = [
              {
                path = var.ingress_path
                pathType = var.ingress_path_type
              }
            ]
          }
        ]
        annotations = {
          "nginx.ingress.kubernetes.io/enable-cors" = "true"
          "nginx.ingress.kubernetes.io/ssl-redirect" = "false"
          "nginx.ingress.kubernetes.io/force-ssl-redirect" = "false"
          "nginx.ingress.kubernetes.io/rewrite-target" = "/"
          "nginx.ingress.kubernetes.io/backend-protocol" = "HTTP"
          "nginx.ingress.kubernetes.io/configuration-snippet" = <<-EOT
            proxy_ssl_verify off;
            proxy_set_header X-Real-IP $remote_addr;
          EOT
        }
        
      }
  #proxy_set_header Host $host;
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