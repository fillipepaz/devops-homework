variable "app_replicas" {
  description = "Number of application replicas"
  type        = number
  default     = 2
}

variable "use_nlb_dns" {
  description = "Whether to use NLB DNS instead of custom domain"
  type        = bool
  default     = true
}

variable "app_domain" {
  description = "Domain name for the application (used when use_nlb_dns is false)"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "release_name" {
  description = "Name of the Helm release"
  type        = string
  default     = "ruby-app"
}

variable "chart_path" {
  description = "Path to the Helm chart"
  type        = string
  default     = "../../../helm/ruby-app"
}

variable "create_namespace" {
  description = "Whether to create the namespace"
  type        = bool
  default     = true
}

variable "ingress_enabled" {
  description = "Enable ingress for the application"
  type        = bool
  default     = true
}

variable "ingress_class_name" {
  description = "Ingress class name"
  type        = string
  default     = "nginx"
}

variable "ingress_path" {
  description = "Path for the ingress rule"
  type        = string
  default     = "/"
}

variable "ingress_path_type" {
  description = "Path type for the ingress rule"
  type        = string
  default     = "Prefix"
}

variable "readiness_probe_enabled" {
  description = "Enable readiness probe"
  type        = bool
  default     = false
}

variable "readiness_probe_initial_delay" {
  description = "Initial delay for readiness probe"
  type        = number
  default     = 10
}

variable "readiness_probe_period" {
  description = "Period for readiness probe"
  type        = number
  default     = 10
}

variable "startup_probe_enabled" {
  description = "Enable startup probe"
  type        = bool
  default     = true
}

variable "startup_probe_initial_delay" {
  description = "Initial delay for startup probe"
  type        = number
  default     = 30
}

variable "startup_probe_period" {
  description = "Period for startup probe"
  type        = number
  default     = 10
}

variable "image_repository" {
  description = "Docker image repository"
  type        = string
  default     = "fstudy/ruby-app"
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "image_pull_policy" {
  description = "Docker image pull policy"
  type        = string
  default     = "Always"
}

variable "hpa_enabled" {
  description = "Enable Horizontal Pod Autoscaler (HPA)"
  type        = bool
  default     = false
  
}

variable "hpa_min_replicas" {
  description = "Minimum number of replicas for HPA"
  type        = number
  default     = 2
}

variable "hpa_max_replicas" {
  description = "Maximum number of replicas for HPA"
  type        = number
  default     = 5
}

variable "hpa_target_cpu_utilization_percentage" {
  description = "Target CPU utilization percentage for HPA"
  type        = number
  default     = 80
}

