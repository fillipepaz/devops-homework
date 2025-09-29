# Data sources for existing VPC and subnets validation
data "aws_vpc" "existing" {
  count = var.create_vpc ? 0 : 1
  id    = var.vpc_id
}

data "aws_subnet" "private" {
  count = var.create_vpc ? 0 : length(var.private_subnets)
  id    = var.private_subnets[count.index]
}

data "aws_subnet" "public" {
  count = var.create_vpc ? 0 : length(var.public_subnets)
  id    = var.public_subnets[count.index]
}