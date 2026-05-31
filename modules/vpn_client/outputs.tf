output "client_vpn_endpoint_id" {
  description = "ID of the Client VPN Endpoint"
  value       = aws_ec2_client_vpn_endpoint.doctor_remote.id
}

output "client_vpn_endpoint_dns_name" {
  description = "DNS name of the Client VPN Endpoint (for .ovpn config)"
  value       = aws_ec2_client_vpn_endpoint.doctor_remote.dns_name
}

output "server_cert_arn" {
  description = "ACM ARN of the server certificate"
  value       = aws_acm_certificate.server.arn
}

output "client_cert_arn" {
  description = "ACM ARN of the client certificate"
  value       = aws_acm_certificate.client.arn
}

output "client_private_key_pem" {
  description = "Client private key PEM (for client .ovpn configuration)"
  value       = tls_private_key.client.private_key_pem
  sensitive   = true
}

output "client_cert_pem" {
  description = "Client certificate PEM (for client .ovpn configuration)"
  value       = tls_locally_signed_cert.client.cert_pem
}
