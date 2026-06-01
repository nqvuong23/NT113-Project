###############################################################
# MODULE 03 – TRANSIT GATEWAY
# Central router. Only 1 VPC Attachment (Production) +
# 2 VPN Attachments (created automatically by vpn_connection).
# 2 Route Tables: OnPremise and Production.
###############################################################

# ── 3.1 Transit Gateway ───────────────────────────────────────
resource "aws_ec2_transit_gateway" "main" {
  description                     = "Central Router Hospital Network"
  amazon_side_asn                 = var.tgw_amazon_side_asn
  auto_accept_shared_attachments  = "disable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"

  tags = {
    Name        = "TGW-Hospital"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── 3.2 TGW VPC Attachment – VPC Production (the only VPC) ───
resource "aws_ec2_transit_gateway_vpc_attachment" "production" {
  transit_gateway_id                              = aws_ec2_transit_gateway.main.id
  vpc_id                                          = var.vpc_production_id
  subnet_ids                                      = [var.subnet_prod_tgw_az_a_id, var.subnet_prod_tgw_az_b_id]
  dns_support                                     = "enable"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name        = "TGW-Attach-VPC-Production"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── 3.3 TGW Route Tables (2 tables) ──────────────────────────

# Route Table 1: OnPremise (for VPN attachments from 2 hospitals)
resource "aws_ec2_transit_gateway_route_table" "onpremise" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = {
    Name        = "TGW-RT-OnPremise"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Route Table 2: Production VPC
resource "aws_ec2_transit_gateway_route_table" "production" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = {
    Name        = "TGW-RT-Production"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── 3.4 TGW Route Table Association – VPC Production ─────────
resource "aws_ec2_transit_gateway_route_table_association" "production" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.production.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.production.id
}

resource "aws_ec2_transit_gateway_route" "onprem_to_production" {
  destination_cidr_block         = var.cidr_vpc_prod
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.production.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.onpremise.id
}

