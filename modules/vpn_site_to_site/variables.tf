variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "tgw_id" {
  description = "Transit Gateway ID"
  type        = string
}

variable "tgw_rt_onpremise_id" {
  description = "TGW Route Table ID for OnPremise (VPN attachments)"
  type        = string
}

variable "tgw_rt_production_id" {
  description = "TGW Route Table ID for Production VPC"
  type        = string
}

variable "onprem_eip_public_ips" {
  description = "Map of EIP public IPs for VPN Appliances (key: 1/2)"
  type        = map(string)
}

variable "cgw_bgp_asn_1" {
  description = "BGP ASN for Customer Gateway Hospital 1"
  type        = number
}

variable "cgw_bgp_asn_2" {
  description = "BGP ASN for Customer Gateway Hospital 2"
  type        = number
}

variable "cidr_onprem_1" {
  description = "CIDR block for Hospital 1"
  type        = string
}

variable "cidr_onprem_2" {
  description = "CIDR block for Hospital 2"
  type        = string
}
