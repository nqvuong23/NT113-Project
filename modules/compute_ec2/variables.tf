variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "key_name" {
  description = "EC2 Key Pair name"
  type        = string
}

variable "ec2_keypair_public_key" {
  description = "Public key content for EC2 key pair"
  type        = string
}

variable "vpn_ami_ubuntu" {
  description = "AMI ID for Ubuntu 22.04 LTS (VPN Appliance)"
  type        = string
}

variable "app_ami_al2023" {
  description = "AMI ID for Amazon Linux 2023 (App Server, Bastion, Workstation)"
  type        = string
}

variable "vpn_appliance_instance_type" {
  description = "Instance type for VPN Appliance"
  type        = string
}

variable "app_server_instance_type" {
  description = "Instance type for App Server"
  type        = string
}

variable "bastion_instance_type" {
  description = "Instance type for Bastion Host"
  type        = string
}

variable "workstation_instance_type" {
  description = "Instance type for OnPremise Workstation"
  type        = string
}

# OnPremise networking (2 hospitals)
variable "onprem_public_subnet_ids" {
  description = "Map of public subnet IDs per hospital (key: 1/2)"
  type        = map(string)
}

variable "onprem_private_subnet_ids" {
  description = "Map of private subnet IDs per hospital (key: Workstation-1, Workstation-2, etc.)"
  type        = map(string)
}

variable "onprem_sg_vpn_appliance_ids" {
  description = "Map of VPN Appliance SG IDs per hospital (key: 1/2)"
  type        = map(string)
}

variable "onprem_eip_allocation_ids" {
  description = "Map of EIP allocation IDs per hospital (key: 1/2)"
  type        = map(string)
}

# IAM Profiles
variable "vpn_appliance_instance_profile" {
  description = "IAM Instance Profile for VPN Appliance"
  type        = string
}

variable "app_server_instance_profile" {
  description = "IAM Instance Profile for App Server"
  type        = string
}

variable "bastion_instance_profile" {
  description = "IAM Instance Profile for Bastion"
  type        = string
}

# Production subnets
variable "subnet_prod_app_az_a_id" {
  description = "Prod App Subnet AZ-A ID"
  type        = string
}

variable "subnet_prod_app_az_b_id" {
  description = "Prod App Subnet AZ-B ID"
  type        = string
}

# Public subnet for Bastion (in Production)
variable "subnet_prod_public_az_a_id" {
  description = "Production Public Subnet AZ-A ID (for Bastion Host)"
  type        = string
}

# Security Groups
variable "sg_app_server_id" {
  description = "Security Group ID for App Server"
  type        = string
}

variable "sg_bastion_id" {
  description = "Security Group ID for Bastion"
  type        = string
}

# KMS
variable "kms_key_general_arn" {
  description = "ARN of the General KMS key (for EBS encryption)"
  type        = string
}

variable "sg_onprem_workstation_ids" {
  description = "Map of Workstation SG IDs per hospital (key: 1/2)"
  type        = map(string)
}