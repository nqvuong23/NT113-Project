variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_production_id" {
  description = "ID of VPC Production (Client VPN endpoint placed here)"
  type        = string
}

variable "subnet_prod_clientvpn_az_a_id" {
  description = "Production ClientVPN Subnet AZ-A ID (min /27 required)"
  type        = string
}

variable "subnet_prod_clientvpn_az_b_id" {
  description = "Production ClientVPN Subnet AZ-B ID (min /27 required)"
  type        = string
}

variable "subnet_prod_app_az_a_cidr" {
  description = "CIDR of Production App Subnet AZ-A (for authorization rule)"
  type        = string
}

variable "subnet_prod_app_az_b_cidr" {
  description = "CIDR of Production App Subnet AZ-B (for authorization rule)"
  type        = string
}

variable "cidr_client_vpn" {
  description = "CIDR block for Client VPN address pool (must be /22 or larger, no overlap with VPC)"
  type        = string
}

variable "sg_client_vpn_id" {
  description = "Security Group ID for Client VPN Endpoint"
  type        = string
}

variable "kms_key_general_arn" {
  description = "ARN of the General KMS key for CloudWatch Logs encryption"
  type        = string
}

variable "vpn_log_retention_days" {
  description = "CloudWatch log retention for VPN connections (days)"
  type        = number
}

variable "vpn_domain" {
  description = "Domain name for VPN certificates (e.g. hospital.internal)"
  type        = string
}

variable "dns_servers" {
  type = list(string)
}