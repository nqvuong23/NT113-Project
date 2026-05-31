variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "s3_medical_data_bucket" {
  description = "Name of the S3 medical data bucket"
  type        = string
}

variable "s3_cloudtrail_bucket" {
  description = "Name of the S3 CloudTrail logs bucket"
  type        = string
}

variable "kms_key_s3_arn" {
  description = "ARN of the S3 KMS key"
  type        = string
}
