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