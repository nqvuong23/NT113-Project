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

variable "vpc_production_id" {
  description = "ID of VPC Production"
  type        = string
}

variable "subnet_prod_app_az_a_id" {
  description = "Prod App Subnet AZ-A ID"
  type        = string
}

variable "subnet_prod_app_az_b_id" {
  description = "Prod App Subnet AZ-B ID"
  type        = string
}

variable "sg_vpc_endpoints_id" {
  description = "Security Group ID for VPC Endpoints"
  type        = string
}

variable "rt_prod_app_az_a_id" {
  description = "Route Table ID for Production App Subnet AZ-A (for S3/DynamoDB Gateway endpoints)"
  type        = string
}

variable "rt_prod_app_az_b_id" {
  description = "Route Table ID for Production App Subnet AZ-B (for S3/DynamoDB Gateway endpoints)"
  type        = string
}
