output "kms_key_general_arn" {
  description = "ARN of the General KMS key"
  value       = aws_kms_key.general.arn
}

output "kms_key_general_id" {
  description = "ID of the General KMS key"
  value       = aws_kms_key.general.key_id
}

output "kms_key_rds_arn" {
  description = "ARN of the RDS KMS key"
  value       = aws_kms_key.rds.arn
}

output "kms_key_rds_id" {
  description = "ID of the RDS KMS key"
  value       = aws_kms_key.rds.key_id
}

output "kms_key_s3_arn" {
  description = "ARN of the S3 Medical Data KMS key"
  value       = aws_kms_key.s3.arn
}

output "kms_key_s3_id" {
  description = "ID of the S3 Medical Data KMS key"
  value       = aws_kms_key.s3.key_id
}
