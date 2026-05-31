variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "az_a" {
  description = "Availability Zone A"
  type        = string
}

variable "vpc_cidr_onprem_1" {
  description = "CIDR block for Hospital 1 OnPremise VPC"
  type        = string
}

variable "vpc_cidr_onprem_2" {
  description = "CIDR block for Hospital 2 OnPremise VPC"
  type        = string
}

variable "public_subnet_cidr_onprem_1" {
  description = "Public subnet CIDR for Hospital 1 (e.g. 192.168.10.0/25)"
  type        = string
}

variable "public_subnet_cidr_onprem_2" {
  description = "Public subnet CIDR for Hospital 2 (e.g. 192.168.20.0/25)"
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

variable "admin_ip_cidr" {
  description = "Admin IP CIDR for SSH access"
  type        = string
}
