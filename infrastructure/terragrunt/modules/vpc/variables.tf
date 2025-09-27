variable "environment" {
  type        = string
  description = "Environment name"
}

variable "create_vpc" {
  type        = bool
  description = "Controls if VPC should be created (it affects all VPC resources)"
  default     = true
}

variable "vpc_id" {
  type        = string
  description = "ID of an existing VPC to use (if you don't want to create a new one)"
  default     = ""
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
  default     = "10.0.0.0/16"  # Provides space for multiple /19 subnets
}

variable "azs" {
  type        = list(string)
  description = "Availability zones"
}

variable "private_subnets" {
  type        = list(string)
  description = "List of existing private subnet IDs to use"
  default     = []
}
variable "project" {
  type        = string
  description = "Project name for tagging"
  default     = "ruby-app"
}

variable "public_subnets" {
  type        = list(string)
  description = "List of existing public subnet IDs to use"
  default     = []
}