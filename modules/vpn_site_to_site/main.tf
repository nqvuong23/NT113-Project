###############################################################
# MODULE 04 – SITE-TO-SITE VPN (2 Hospitals)
# Customer Gateways, VPN Connections (2 tunnels each), Static Routes
# TGW Route Table Associations and Production→Hospital routes
###############################################################

# ── 4.1 Customer Gateways ─────────────────────────────────────
resource "aws_customer_gateway" "hospital" {
  for_each = {
    "1" = { bgp_asn = var.cgw_bgp_asn_1, ip = var.onprem_eip_public_ips["1"] }
    "2" = { bgp_asn = var.cgw_bgp_asn_2, ip = var.onprem_eip_public_ips["2"] }
  }

  bgp_asn    = each.value.bgp_asn
  ip_address = each.value.ip
  type       = "ipsec.1"

  tags = {
    Name        = "CGW-Hospital-${each.key}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── 4.2 VPN Connections ───────────────────────────────────────
resource "aws_vpn_connection" "hospital" {
  for_each = aws_customer_gateway.hospital

  customer_gateway_id = each.value.id
  transit_gateway_id  = var.tgw_id
  type                = "ipsec.1"
  static_routes_only  = true

  # Tunnel 1 (Primary)
  tunnel1_ike_versions                 = ["ikev2"]
  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase1_dh_group_numbers      = [14]
  tunnel1_phase2_encryption_algorithms = ["AES256"]
  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase2_dh_group_numbers      = [14]

  # Tunnel 2 (HA Backup)
  tunnel2_ike_versions                 = ["ikev2"]
  tunnel2_phase1_encryption_algorithms = ["AES256"]
  tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase1_dh_group_numbers      = [14]
  tunnel2_phase2_encryption_algorithms = ["AES256"]
  tunnel2_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase2_dh_group_numbers      = [14]

  tags = {
    Name        = "VPN-Hospital-${each.key}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── 4.3 TGW Static Routes: Production → Hospitals ─────────────
# NOTE: aws_vpn_connection_route is NOT supported for TGW-attached VPNs.
# For TGW VPNs with static_routes_only=true, routes must be added via
# aws_ec2_transit_gateway_route on the TGW route table.
# Propagation also won't auto-learn routes without BGP.

resource "aws_ec2_transit_gateway_route" "prod_to_hospital" {
  for_each = {
    "1" = { cidr = var.cidr_onprem_1, attachment_id = aws_vpn_connection.hospital["1"].transit_gateway_attachment_id }
    "2" = { cidr = var.cidr_onprem_2, attachment_id = aws_vpn_connection.hospital["2"].transit_gateway_attachment_id }
  }

  destination_cidr_block         = each.value.cidr
  transit_gateway_attachment_id  = each.value.attachment_id
  transit_gateway_route_table_id = var.tgw_rt_production_id
}

# ── TGW Route Table Associations for VPN Attachments ──────────
# Associate each VPN attachment to the OnPremise route table
resource "aws_ec2_transit_gateway_route_table_association" "vpn_hospital" {
  for_each = aws_vpn_connection.hospital

  transit_gateway_attachment_id  = each.value.transit_gateway_attachment_id
  transit_gateway_route_table_id = var.tgw_rt_onpremise_id
}
