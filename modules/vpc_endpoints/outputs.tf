output "s3_prod_endpoint_id" {
  description = "ID of S3 Gateway Endpoint in Production"
  value       = aws_vpc_endpoint.s3_prod.id
}

output "dynamodb_prod_endpoint_id" {
  description = "ID of DynamoDB Gateway Endpoint in Production"
  value       = aws_vpc_endpoint.dynamodb_prod.id
}

output "kms_prod_endpoint_id" {
  description = "ID of KMS Interface Endpoint in Production"
  value       = aws_vpc_endpoint.kms_prod.id
}

output "secretsmanager_prod_endpoint_id" {
  description = "ID of Secrets Manager Interface Endpoint in Production"
  value       = aws_vpc_endpoint.secretsmanager_prod.id
}
