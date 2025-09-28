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

variable "enable_pod_eni" {
  description = "Enable pod ENI for VPC CNI addon"
  type        = bool
  default     = false
}

variable "enable_prefix_delegation" {
  description = "Enable prefix delegation for VPC CNI addon"
  type        = bool
  default     = true
}

variable "volume_type" {
  description = "EBS volume type for worker nodes"
  type        = string
  default     = "gp3"
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

variable "api_server_public_access" {
  description = "Enable public access to EKS API server"
  type        = bool
  default     = true
}
variable "capacity_type" {
  description = "Capacity type for node group (e.g., ON_DEMAND, SPOT)"
  type        = string
  default     = "ON_DEMAND"
  
}

variable "volume_size" {
  description = "EBS volume size for each node in GB"
  type        = number
  default     = 50
  
}