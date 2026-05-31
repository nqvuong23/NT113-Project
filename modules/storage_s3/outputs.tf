output "medical_data_bucket_name" {
  description = "Name of the medical data S3 bucket"
  value       = aws_s3_bucket.medical_data.bucket
}

output "medical_data_bucket_arn" {
  description = "ARN of the medical data S3 bucket"
  value       = aws_s3_bucket.medical_data.arn
}

output "cloudtrail_bucket_name" {
  description = "Name of the CloudTrail logs S3 bucket"
  value       = aws_s3_bucket.cloudtrail_logs.bucket
}

output "cloudtrail_bucket_arn" {
  description = "ARN of the CloudTrail logs S3 bucket"
  value       = aws_s3_bucket.cloudtrail_logs.arn
}

output "alb_logs_bucket_name" {
  description = "Name of the ALB logs S3 bucket"
  value       = aws_s3_bucket.alb_logs.bucket
}

output "alb_logs_bucket_arn" {
  description = "ARN of the ALB logs S3 bucket"
  value       = aws_s3_bucket.alb_logs.arn
}

