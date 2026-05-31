output "private_zone_id" {
  description = "ID of the Private Hosted Zone"
  value       = aws_route53_zone.hospital_internal.zone_id
}

output "his_app_fqdn" {
  description = "FQDN for HIS App endpoint"
  value       = aws_route53_record.his_app.fqdn
}

output "db_fqdn" {
  description = "FQDN for DB endpoint"
  value       = aws_route53_record.db.fqdn
}

output "health_check_id" {
  description = "Route53 Health Check ID for HIS endpoint"
  value       = aws_route53_health_check.his_endpoint.id
}
