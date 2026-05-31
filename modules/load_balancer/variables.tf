variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
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

variable "sg_alb_internal_id" {
  description = "Security Group ID for Internal ALB"
  type        = string
}

variable "app_server_az_a_id" {
  description = "EC2 App Server AZ-A instance ID"
  type        = string
}

variable "app_server_az_b_id" {
  description = "EC2 App Server AZ-B instance ID"
  type        = string
}

variable "alb_logs_bucket_name" {
  description = "S3 bucket name for ALB access logs"
  type        = string
}

variable "alb_certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener"
  type        = string
}
