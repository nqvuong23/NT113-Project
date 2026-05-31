variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_production_id" {
  description = "ID of VPC Production (all SGs live here)"
  type        = string
}

variable "cidr_onprem_1" {
  description = "CIDR block for Hospital 1"
  type        = string
}

variable "cidr_onprem_2" {
  description = "CIDR block for Hospital 2"
  type        = string
}

variable "cidr_client_vpn" {
  description = "CIDR block for Client VPN address pool"
  type        = string
}

variable "cidr_vpc_prod" {
  description = "CIDR block of VPC Production (for VPC Endpoint SG)"
  type        = string
}

variable "admin_ip_cidr" {
  description = "Admin IP CIDR for SSH access to Bastion"
  type        = string
}

variable "subnet_prod_db_az_a_id" {
  description = "ID of Prod DB Subnet AZ-A (for NACL)"
  type        = string
}

variable "subnet_prod_db_az_b_id" {
  description = "ID of Prod DB Subnet AZ-B (for NACL)"
  type        = string
}

variable "subnet_prod_app_az_a_cidr" {
  description = "CIDR of App Subnet AZ-A (for granular NACL rules)"
  type        = string
}

variable "subnet_prod_app_az_b_cidr" {
  description = "CIDR of App Subnet AZ-B (for granular NACL rules)"
  type        = string
}

# Map of onprem VPC IDs (key: "1" = Hospital 1, "2" = Hospital 2)
variable "onprem_vpc_ids" {
  description = "Map of OnPremise VPC IDs (key: 1/2)"
  type        = map(string)
}

variable "workstation_subnet_onprem_ids" {
  description = "Map of Workstation subnet IDs per hospital (key: 1/2)"
  type        = map(string)
}

variable "iot_subnet_onprem_ids" {
  description = "Map of IOT subnet IDs per hospital (key: 1/2)"
  type        = map(string)
}

variable "wifi_subnet_onprem_ids" {
  description = "Map of Wifi subnet IDs per hospital (key: 1/2)"
  type        = map(string)
}

variable "workstation_subnet_onprem_cidrs" {
  description = "Map of Workstation subnet CIDRs per hospital (key: 1/2)"
  type        = map(string)
}

variable "iot_subnet_onprem_cidrs" {
  description = "Map of IOT subnet CIDRs per hospital (key: 1/2)"
  type        = map(string)
}

variable "wifi_subnet_onprem_cidrs" {
  description = "Map of Wifi subnet CIDRs per hospital (key: 1/2)"
  type        = map(string)
}