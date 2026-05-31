variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

# VPC ID
variable "vpc_production_id" {
  description = "ID of VPC Production"
  type        = string
}

# Gateway IDs (all in Production VPC)
variable "igw_prod_id" {
  description = "Internet Gateway ID for Production VPC"
  type        = string
}

variable "tgw_id" {
  description = "Transit Gateway ID"
  type        = string
}

variable "nat_gateway_prod_az_a_id" {
  description = "NAT Gateway ID in Production AZ-A"
  type        = string
}

variable "nat_gateway_prod_az_b_id" {
  description = "NAT Gateway ID in Production AZ-B"
  type        = string
}

# Subnet IDs – Production (all 10 subnets)
variable "subnet_prod_public_az_a_id" {
  description = "Production Public Subnet AZ-A ID"
  type        = string
}

variable "subnet_prod_public_az_b_id" {
  description = "Production Public Subnet AZ-B ID"
  type        = string
}

variable "subnet_prod_tgw_az_a_id" {
  description = "Production TGW Subnet AZ-A ID"
  type        = string
}

variable "subnet_prod_tgw_az_b_id" {
  description = "Production TGW Subnet AZ-B ID"
  type        = string
}

variable "subnet_prod_clientvpn_az_a_id" {
  description = "Production Client VPN Subnet AZ-A ID"
  type        = string
}

variable "subnet_prod_clientvpn_az_b_id" {
  description = "Production Client VPN Subnet AZ-B ID"
  type        = string
}

variable "subnet_prod_app_az_a_id" {
  description = "Production App Subnet AZ-A ID"
  type        = string
}

variable "subnet_prod_app_az_b_id" {
  description = "Production App Subnet AZ-B ID"
  type        = string
}

variable "subnet_prod_db_az_a_id" {
  description = "Production DB Subnet AZ-A ID"
  type        = string
}

variable "subnet_prod_db_az_b_id" {
  description = "Production DB Subnet AZ-B ID"
  type        = string
}

# CIDRs for routing
variable "cidr_onprem_1" {
  description = "CIDR block for Hospital 1"
  type        = string
}

variable "cidr_onprem_2" {
  description = "CIDR block for Hospital 2"
  type        = string
}

# VPC production CIDR
variable "vpc_production_cidr" {
  description = "CIDR block of Production VPC"
  type        = string
}

# OnPremise VPC IDs (key: "1" = Hospital 1, "2" = Hospital 2)
variable "onprem_vpc_ids" {
  description = "Map of OnPremise VPC IDs (key: 1/2)"
  type        = map(string)
}

# OnPremise Internet Gateway IDs (key: "1"/"2")
variable "igw_onprem_ids" {
  description = "Map of OnPremise Internet Gateway IDs (key: 1/2)"
  type        = map(string)
}

# OnPremise Public Subnet IDs (key: "1"/"2")
variable "onprem_public_subnet_ids" {
  description = "Map of OnPremise Public Subnet IDs (key: 1/2)"
  type        = map(string)
}

# OnPremise Private Subnet IDs used for private route table association (key: "1"/"2")
variable "onprem_private_subnet_ids" {
  description = "Map of OnPremise Private Subnet IDs (Workstation) for route table association (key: 1/2)"
  type        = map(string)
}

# Primary ENI IDs of VPN Appliances (key: "1"/"2")
variable "vpn_appliance_primary_eni_ids" {
  description = "Map of primary ENI IDs for VPN Appliance EC2 instances (key: 1/2)"
  type        = map(string)
}

# NAT Gateway for OnPrem 1
variable "nat_gateway_onprem_1" {
  description = "NAT Gateway ID for OnPremise Hospital 1"
  type        = string
}
