variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "private_zone_name" {
  description = "Private hosted zone domain name (e.g. hospital.internal)"
  type        = string
}

variable "vpc_production_id" {
  description = "ID of VPC Production (the only VPC – zone associated here)"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the Internal ALB"
  type        = string
}

variable "alb_zone_id" {
  description = "Hosted Zone ID of the Internal ALB"
  type        = string
}

variable "rds_address" {
  description = "RDS instance hostname/address"
  type        = string
}
