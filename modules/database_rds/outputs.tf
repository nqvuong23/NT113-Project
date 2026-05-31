output "rds_endpoint" {
  description = "RDS instance endpoint (hostname:port)"
  value       = aws_db_instance.hospital_prod.endpoint
}

output "rds_address" {
  description = "RDS instance hostname"
  value       = aws_db_instance.hospital_prod.address
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.hospital_prod.port
}

output "rds_identifier" {
  description = "RDS instance identifier"
  value       = aws_db_instance.hospital_prod.identifier
}

output "rds_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.hospital_prod.arn
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret for DB credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}
