###############################################################
# MODULE 05 – AWS CLIENT VPN (Remote Doctor Access)
# TLS certs via TLS provider, ACM import, VPN Endpoint
# Endpoint placed in VPC Production ClientVPN subnets.
###############################################################

# ── 5.1 TLS Self-Signed Certificates (Demo/Dev) ───────────────

# CA Key + Self-Signed Cert
resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem = tls_private_key.ca.private_key_pem

  subject {
    common_name  = "hospital-ca"
    organization = "Hospital IT"
  }

  validity_period_hours = 87600 # 10 years
  is_ca_certificate     = true

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature",
  ]
}

# Server Key + Certificate
resource "tls_private_key" "server" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "server" {
  private_key_pem = tls_private_key.server.private_key_pem

  subject {
    common_name  = "server.${var.vpn_domain}"
    organization = "Hospital IT"
  }
}

resource "tls_locally_signed_cert" "server" {
  cert_request_pem   = tls_cert_request.server.cert_request_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = 87600

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# Client Key + Certificate
resource "tls_private_key" "client" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "client" {
  private_key_pem = tls_private_key.client.private_key_pem

  subject {
    common_name  = "client.${var.vpn_domain}"
    organization = "Hospital IT"
  }
}

resource "tls_locally_signed_cert" "client" {
  cert_request_pem   = tls_cert_request.client.cert_request_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = 87600

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
  ]
}

# ── Import certificates to ACM ────────────────────────────────
resource "aws_acm_certificate" "server" {
  private_key       = tls_private_key.server.private_key_pem
  certificate_body  = tls_locally_signed_cert.server.cert_pem
  certificate_chain = tls_self_signed_cert.ca.cert_pem

  tags = {
    Name        = "ClientVPN-Server-Cert"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_acm_certificate" "client" {
  private_key       = tls_private_key.client.private_key_pem
  certificate_body  = tls_locally_signed_cert.client.cert_pem
  certificate_chain = tls_self_signed_cert.ca.cert_pem

  tags = {
    Name        = "ClientVPN-Client-Cert"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── 5.2 CloudWatch Log Group ──────────────────────────────────
resource "aws_cloudwatch_log_group" "client_vpn" {
  name              = "/hospital/clientvpn/connections"
  retention_in_days = var.vpn_log_retention_days
  kms_key_id        = var.kms_key_general_arn

  tags = {
    Name        = "CWLogs-ClientVPN"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_log_stream" "client_vpn" {
  name           = "client-vpn-connections"
  log_group_name = aws_cloudwatch_log_group.client_vpn.name
}

# ── 5.3 Client VPN Endpoint ───────────────────────────────────
# Endpoint is placed in VPC Production (not Hub – Hub removed in v2)
resource "aws_ec2_client_vpn_endpoint" "doctor_remote" {
  description            = "Doctor Remote Access VPN"
  server_certificate_arn = aws_acm_certificate.server.arn
  client_cidr_block      = var.cidr_client_vpn
  vpc_id                 = var.vpc_production_id
  security_group_ids     = [var.sg_client_vpn_id]
  split_tunnel           = true # Only AWS traffic goes through VPN
  dns_servers = var.dns_servers

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.client.arn
  }

  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.client_vpn.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.client_vpn.name
  }

  tags = {
    Name        = "ClientVPN-Doctor-Remote"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── 5.4 Client VPN Network Associations (2 AZ) ────────────────
# Associate to ClientVPN subnets in Production VPC
resource "aws_ec2_client_vpn_network_association" "az_a" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.doctor_remote.id
  subnet_id              = var.subnet_prod_clientvpn_az_a_id
}

resource "aws_ec2_client_vpn_network_association" "az_b" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.doctor_remote.id
  subnet_id              = var.subnet_prod_clientvpn_az_b_id
}

# ── 5.5 Client VPN Authorization Rules ────────────────────────
# Doctors can access App Subnet AZ-A and AZ-B (HIS application)
# They cannot access DB Subnet, TGW Subnet, or internet via VPN.
resource "aws_ec2_client_vpn_authorization_rule" "allow_app_az_a" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.doctor_remote.id
  target_network_cidr    = var.subnet_prod_app_az_a_cidr
  authorize_all_groups   = true
  description            = "Allow remote doctors to access HIS App Subnet AZ-A"
}

resource "aws_ec2_client_vpn_authorization_rule" "allow_app_az_b" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.doctor_remote.id
  target_network_cidr    = var.subnet_prod_app_az_b_cidr
  authorize_all_groups   = true
  description            = "Allow remote doctors to access HIS App Subnet AZ-B"
}
