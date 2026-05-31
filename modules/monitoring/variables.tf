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

variable "admin_email" {
  description = "Email address for SNS alert notifications"
  type        = string
}

# KMS
variable "kms_key_general_arn" {
  description = "ARN of the General KMS key"
  type        = string
}

variable "kms_key_s3_arn" {
  description = "ARN of the S3 KMS key (for CloudTrail)"
  type        = string
}

# CloudTrail
variable "cloudtrail_bucket_name" {
  description = "S3 bucket name for CloudTrail logs"
  type        = string
}

variable "cloudtrail_role_arn" {
  description = "IAM Role ARN for CloudTrail → CloudWatch Logs"
  type        = string
}

# Log Retention
variable "flowlogs_retention_days" {
  description = "Retention period (days) for VPC Flow Log groups"
  type        = number
}

variable "cloudtrail_log_retention_days" {
  description = "Retention period (days) for CloudTrail log group"
  type        = number
}

variable "appserver_log_retention_days" {
  description = "Retention period (days) for App Server log group"
  type        = number
}

# VPC IDs for Flow Logs
variable "vpc_production_id" {
  description = "ID of VPC Production (the only VPC in v2)"
  type        = string
}

variable "vpc_flowlogs_role_arn" {
  description = "IAM Role ARN for VPC Flow Logs → CloudWatch"
  type        = string
}

# VPN Connection IDs for Alarms (2 hospitals only)
variable "vpn_connection_id_1" {
  description = "VPN Connection ID for Hospital 1"
  type        = string
}

variable "vpn_connection_id_2" {
  description = "VPN Connection ID for Hospital 2"
  type        = string
}

# RDS
variable "rds_identifier" {
  description = "RDS instance identifier"
  type        = string
}

# ALB
variable "alb_arn_suffix" {
  description = "ALB ARN suffix (for CW metric dimensions)"
  type        = string
}

variable "tg_arn_suffix" {
  description = "Target Group ARN suffix (for CW metric dimensions)"
  type        = string
}

# EC2
variable "app_server_az_a_id" {
  description = "App Server AZ-A Instance ID"
  type        = string
}

variable "app_server_az_b_id" {
  description = "App Server AZ-B Instance ID"
  type        = string
}

# Route53 Health Check
variable "route53_health_check_id" {
  description = "Route53 Health Check ID for HIS endpoint"
  type        = string
}
