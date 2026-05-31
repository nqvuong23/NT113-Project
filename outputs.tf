###############################################################
# ROOT OUTPUTS – Key values from all modules (v2)
###############################################################

# ── KMS Keys ───────────────────────────────────────────────────
output "kms_key_general_arn" {
  description = "ARN of General KMS Key"
  value       = module.kms.kms_key_general_arn
}

output "kms_key_rds_arn" {
  description = "ARN of RDS KMS Key"
  value       = module.kms.kms_key_rds_arn
}

output "kms_key_s3_arn" {
  description = "ARN of S3 Medical Data KMS Key"
  value       = module.kms.kms_key_s3_arn
}

# ── Transit Gateway ────────────────────────────────────────────
output "tgw_id" {
  description = "Transit Gateway ID (central router)"
  value       = module.transit_gateway.tgw_id
}

output "tgw_vpc_attachment_id" {
  description = "TGW Attachment ID for VPC Production"
  value       = module.transit_gateway.tgw_attachment_production_id
}

# ── VPC Production ──────────────────────────────────────────────
output "nat_gw_az_a_id" {
  description = "NAT Gateway ID in AZ-A"
  value       = module.vpc_production.nat_gateway_az_a_id
}

output "nat_gw_az_b_id" {
  description = "NAT Gateway ID in AZ-B"
  value       = module.vpc_production.nat_gateway_az_b_id
}

# ── VPN Site-to-Site ───────────────────────────────────────────
output "vpn_tunnel1_addresses" {
  description = "VPN Tunnel 1 outside IPs for each hospital – configure StrongSwan (key: 1/2)"
  value       = module.vpn_site_to_site.vpn_tunnel1_addresses
}

output "vpn_tunnel1_preshared_keys" {
  description = "VPN Tunnel 1 pre-shared keys per hospital (key: 1/2)"
  value       = module.vpn_site_to_site.vpn_tunnel1_preshared_keys
  sensitive   = true
}

output "vpn_tunnel2_addresses" {
  description = "VPN Tunnel 2 outside IPs for each hospital – HA backup (key: 1/2)"
  value       = module.vpn_site_to_site.vpn_tunnel2_addresses
}

output "vpn_tunnel2_preshared_keys" {
  description = "VPN Tunnel 2 pre-shared keys per hospital – HA backup (key: 1/2)"
  value       = module.vpn_site_to_site.vpn_tunnel2_preshared_keys
  sensitive   = true
}

# ── Client VPN ──────────────────────────────────────────────────
output "client_vpn_endpoint_id" {
  description = "Client VPN Endpoint ID – use for .ovpn config download"
  value       = module.vpn_client.client_vpn_endpoint_id
}

output "client_vpn_endpoint_dns_name" {
  description = "Client VPN Endpoint DNS name"
  value       = module.vpn_client.client_vpn_endpoint_dns_name
}

output "client_private_key_pem" {
  description = "Client private key PEM (for client .ovpn configuration)"
  value       = module.vpn_client.client_private_key_pem
  sensitive   = true
}

output "client_cert_pem" {
  description = "Client certificate PEM (for client .ovpn configuration)"
  value       = module.vpn_client.client_cert_pem
}

# ── ALB ────────────────────────────────────────────────────────
output "alb_dns_name" {
  description = "Internal ALB DNS name"
  value       = module.load_balancer.alb_dns_name
}

# ── RDS ────────────────────────────────────────────────────────
output "rds_endpoint" {
  description = "RDS instance endpoint (hostname:port)"
  value       = module.database_rds.rds_endpoint
}

output "db_secret_arn" {
  description = "ARN of the DB credentials secret in Secrets Manager"
  value       = module.database_rds.db_secret_arn
}

# ── EC2 Bastion ────────────────────────────────────────────────
# output "bastion_public_ip" {
#   description = "Public IP of the Bastion Host (Production Public Subnet)"
#   value       = module.compute_ec2.bastion_public_ip
# }

# ── VPN Appliance EIPs ──────────────────────────────────────────
output "vpn_appliance_eip_public_ips" {
  description = "Public IP addresses of hospital VPN Appliances (key: 1/2)"
  value       = module.vpc_onpremise.eip_public_ips
}

# ── SNS Topic ──────────────────────────────────────────────────
output "sns_alerts_arn" {
  description = "ARN of the Hospital IT Alerts SNS Topic"
  value       = module.monitoring.sns_topic_arn
}

# ── DNS ────────────────────────────────────────────────────────
output "his_app_fqdn" {
  description = "FQDN for HIS App (Internal ALB)"
  value       = module.dns_route53.his_app_fqdn
}

output "db_fqdn" {
  description = "FQDN for DB access endpoint"
  value       = module.dns_route53.db_fqdn
}
