output "application_url" {
  description = "The URL where the application is accessible"
  value       = var.use_nlb_dns ? data.kubernetes_service.ingress_nginx.status.0.load_balancer.0.ingress.0.hostname : var.app_domain
}