variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "cidr_vpc_prod" {
  description = "CIDR block for VPC Production (e.g. 10.0.4.0/22)"
  type        = string
}

variable "az_a" {
  description = "First availability zone"
  type        = string
}

variable "az_b" {
  description = "Second availability zone"
  type        = string
}

# TGW subnets (for Transit Gateway ENIs)
variable "subnet_prod_tgw_az_a" {
  description = "CIDR for TGW Subnet AZ-A (e.g. 10.0.4.0/28)"
  type        = string
}

variable "subnet_prod_tgw_az_b" {
  description = "CIDR for TGW Subnet AZ-B (e.g. 10.0.5.64/28)"
  type        = string
}

# Client VPN subnets (for Client VPN Endpoint ENIs – min /27)
variable "subnet_prod_clientvpn_az_a" {
  description = "CIDR for Client VPN Subnet AZ-A (e.g. 10.0.4.16/27)"
  type        = string
}

variable "subnet_prod_clientvpn_az_b" {
  description = "CIDR for Client VPN Subnet AZ-B (e.g. 10.0.5.80/27)"
  type        = string
}

# Public subnets (for NAT Gateway placement)
variable "subnet_prod_public_az_a" {
  description = "CIDR for Public Subnet AZ-A (e.g. 10.0.4.48/28)"
  type        = string
}

variable "subnet_prod_public_az_b" {
  description = "CIDR for Public Subnet AZ-B (e.g. 10.0.5.112/28)"
  type        = string
}

# App subnets (EC2 HIS App Servers, Internal ALB)
variable "subnet_prod_app_az_a" {
  description = "CIDR for App Subnet AZ-A (e.g. 10.0.4.64/25)"
  type        = string
}

variable "subnet_prod_app_az_b" {
  description = "CIDR for App Subnet AZ-B (e.g. 10.0.5.128/25)"
  type        = string
}

# DB subnets (RDS – isolated)
variable "subnet_prod_db_az_a" {
  description = "CIDR for DB Subnet AZ-A (e.g. 10.0.5.0/26)"
  type        = string
}

variable "subnet_prod_db_az_b" {
  description = "CIDR for DB Subnet AZ-B (e.g. 10.0.6.0/26)"
  type        = string
}
