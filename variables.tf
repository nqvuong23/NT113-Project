variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
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

# VPC CIDRs
variable "vpc_cidr_prod" {
  description = "CIDR block for VPC Production (the single AWS VPC)"
  type        = string
}

variable "subnet_prod_tgw_az_a_cidr" {
  description = "CIDR block for VPC Production (the single AWS VPC)"
  type        = string
}

variable "subnet_prod_tgw_az_b_cidr" {
  description = "CIDR block for VPC Production (the single AWS VPC)"
  type        = string
}

variable "subnet_prod_clientvpn_az_a_cidr" {
  description = "CIDR block for VPC Production (the single AWS VPC)"
  type        = string
}

variable "subnet_prod_clientvpn_az_b_cidr" {
  description = "CIDR block for VPC Production (the single AWS VPC)"
  type        = string
}

variable "subnet_prod_public_az_a_cidr" {
  description = "CIDR block for VPC Production (the single AWS VPC)"
  type        = string
}

variable "subnet_prod_public_az_b_cidr" {
  description = "CIDR block for VPC Production (the single AWS VPC)"
  type        = string
}

variable "subnet_prod_app_az_a_cidr" {
  description = "CIDR block for VPC Production (the single AWS VPC)"
  type        = string
}

variable "subnet_prod_app_az_b_cidr" {
  description = "CIDR block for VPC Production (the single AWS VPC)"
  type        = string
}

variable "subnet_prod_db_az_a_cidr" {
  description = "CIDR block for VPC Production (the single AWS VPC)"
  type        = string
}
variable "subnet_prod_db_az_b_cidr" {
  description = "CIDR block for VPC Production (the single AWS VPC)"
  type        = string
}

variable "vpc_cidr_onprem_1" {
  description = "CIDR block for Hospital 1 OnPremise"
  type        = string
}

variable "public_subnet_cidr_onprem_1" {
  description = "CIDR block for Hospital 2 OnPremise"
  type        = string
}

variable "workstation_subnet_cidr_onprem_1" {
  description = "CIDR block for Hospital 2 OnPremise"
  type        = string
}

variable "iot_subnet_cidr_onprem_1" {
  description = "CIDR block for Hospital 2 OnPremise"
  type        = string
}

variable "wifi_subnet_cidr_onprem_1" {
  description = "CIDR block for Hospital 2 OnPremise"
  type        = string
}

variable "vpc_cidr_onprem_2" {
  description = "CIDR block for Hospital 2 OnPremise"
  type        = string
}

variable "public_subnet_cidr_onprem_2" {
  description = "CIDR block for Hospital 2 OnPremise"
  type        = string
}

variable "workstation_subnet_cidr_onprem_2" {
  description = "CIDR block for Hospital 2 OnPremise"
  type        = string
}

variable "iot_subnet_cidr_onprem_2" {
  description = "CIDR block for Hospital 2 OnPremise"
  type        = string
}

variable "wifi_subnet_cidr_onprem_2" {
  description = "CIDR block for Hospital 2 OnPremise"
  type        = string
}

variable "client_vpn_cidr" {
  description = "CIDR block for Client VPN address pool (must be /22 or larger)"
  type        = string
}

variable "admin_email" {
  description = "Admin email for SNS alerts"
  type        = string
}

variable "admin_ip_cidr" {
  description = "Admin IP CIDR for SSH access to Bastion/VPN Appliance"
  type        = string
}

variable "db_password" {
  description = "Master password for RDS database"
  type        = string
  sensitive   = true
}

variable "vpn_ami_ubuntu" {
  description = "AMI ID for Ubuntu 22.04 LTS (ap-southeast-1) - for VPN Appliance"
  type        = string
}

variable "app_ami_al2023" {
  description = "AMI ID for Amazon Linux 2023 (ap-southeast-1) - for App/Bastion"
  type        = string
}

variable "alb_certificate_arn" {
  description = "ACM Certificate ARN for internal ALB HTTPS listener"
  type        = string
}