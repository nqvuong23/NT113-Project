variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "tgw_amazon_side_asn" {
  description = "Amazon side ASN for the Transit Gateway"
  type        = number
}

variable "vpc_production_id" {
  description = "ID of VPC Production"
  type        = string
}

variable "subnet_prod_tgw_az_a_id" {
  description = "ID of Production TGW Subnet AZ-A"
  type        = string
}

variable "subnet_prod_tgw_az_b_id" {
  description = "ID of Production TGW Subnet AZ-B"
  type        = string
}

