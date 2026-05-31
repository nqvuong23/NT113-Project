variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "medical_data_bucket_name" {
  description = "Name for the medical data S3 bucket"
  type        = string
}

variable "cloudtrail_bucket_name" {
  description = "Name for the CloudTrail logs S3 bucket"
  type        = string
}

variable "terraform_state_bucket_name" {
  description = "Name for the Terraform state S3 bucket"
  type        = string
}

variable "alb_logs_bucket_name" {
  description = "Name for the ALB access logs S3 bucket"
  type        = string
}

variable "dynamodb_lock_table_name" {
  description = "Name for the DynamoDB Terraform lock table"
  type        = string
}

variable "kms_key_s3_arn" {
  description = "ARN of the S3 KMS key"
  type        = string
}

variable "kms_key_general_arn" {
  description = "ARN of the General KMS key"
  type        = string
}
