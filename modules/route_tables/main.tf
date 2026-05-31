###############################################################
# MODULE 06 – ROUTE TABLES
# Full routing for VPC Production (all subnet types) and
# OnPremise VPCs (2 hospitals). Hub and Shared Services removed.
###############################################################

# ════════════════════════════════════════════════════════════
# VPC PRODUCTION ROUTE TABLES
# ════════════════════════════════════════════════════════════

# ── 6.3 RT: Public Subnets (NAT GW → Internet) ───────────────
resource "aws_route_table" "prod_public" {
  vpc_id = var.vpc_production_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.igw_prod_id
  }

  tags = {
    Name        = "RT-Prod-Public"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_route_table_association" "prod_public_az_a" {
  subnet_id      = var.subnet_prod_public_az_a_id
  route_table_id = aws_route_table.prod_public.id
}

resource "aws_route_table_association" "prod_public_az_b" {
  subnet_id      = var.subnet_prod_public_az_b_id
  route_table_id = aws_route_table.prod_public.id
}

# ── 6.4 RT: TGW Subnet (local only – TGW ENI, no extra routes) ──
resource "aws_route_table" "prod_tgw" {
  vpc_id = var.vpc_production_id

  # No routes – only local VPC traffic. TGW handles its own routing.
  tags = {
    Name        = "RT-Prod-TGW"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_route_table_association" "prod_tgw_az_a" {
  subnet_id      = var.subnet_prod_tgw_az_a_id
  route_table_id = aws_route_table.prod_tgw.id
}

resource "aws_route_table_association" "prod_tgw_az_b" {
  subnet_id      = var.subnet_prod_tgw_az_b_id
  route_table_id = aws_route_table.prod_tgw.id
}

# ── 6.5 RT: Client VPN Subnet (local only – VPN Endpoint ENI) ──
resource "aws_route_table" "prod_clientvpn" {
  vpc_id = var.vpc_production_id

  # No routes – AWS Client VPN handles internal routing automatically.
  tags = {
    Name        = "RT-Prod-ClientVPN"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_route_table_association" "prod_clientvpn_az_a" {
  subnet_id      = var.subnet_prod_clientvpn_az_a_id
  route_table_id = aws_route_table.prod_clientvpn.id
}

resource "aws_route_table_association" "prod_clientvpn_az_b" {
  subnet_id      = var.subnet_prod_clientvpn_az_b_id
  route_table_id = aws_route_table.prod_clientvpn.id
}

# ── 6.6 RT: App Subnet AZ-A (NAT GW AZ-A + TGW for hospitals) ──
resource "aws_route_table" "prod_app_az_a" {
  vpc_id = var.vpc_production_id

  # Default route: NAT Gateway AZ-A (for software updates)
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.nat_gateway_prod_az_a_id
  }

  # Routes to on-premise hospitals via TGW
  route {
    cidr_block         = var.cidr_onprem_1
    transit_gateway_id = var.tgw_id
  }

  route {
    cidr_block         = var.cidr_onprem_2
    transit_gateway_id = var.tgw_id
  }

  tags = {
    Name        = "RT-Prod-App-AZ-A"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_route_table_association" "prod_app_az_a" {
  subnet_id      = var.subnet_prod_app_az_a_id
  route_table_id = aws_route_table.prod_app_az_a.id
}

# ── 6.7 RT: App Subnet AZ-B (NAT GW AZ-B + TGW for hospitals) ──
resource "aws_route_table" "prod_app_az_b" {
  vpc_id = var.vpc_production_id

  # Default route: NAT Gateway AZ-B (AZ-aware for HA)
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.nat_gateway_prod_az_b_id
  }

  # Routes to on-premise hospitals via TGW
  route {
    cidr_block         = var.cidr_onprem_1
    transit_gateway_id = var.tgw_id
  }

  route {
    cidr_block         = var.cidr_onprem_2
    transit_gateway_id = var.tgw_id
  }

  tags = {
    Name        = "RT-Prod-App-AZ-B"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_route_table_association" "prod_app_az_b" {
  subnet_id      = var.subnet_prod_app_az_b_id
  route_table_id = aws_route_table.prod_app_az_b.id
}

# ── 6.8 RT: DB Subnet (Isolated – local only) ────────────────
resource "aws_route_table" "prod_db" {
  vpc_id = var.vpc_production_id

  # No routes – DB subnet is fully isolated. Only App→DB via SG.
  tags = {
    Name        = "RT-Prod-DB-Isolated"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_route_table_association" "prod_db_az_a" {
  subnet_id      = var.subnet_prod_db_az_a_id
  route_table_id = aws_route_table.prod_db.id
}

resource "aws_route_table_association" "prod_db_az_b" {
  subnet_id      = var.subnet_prod_db_az_b_id
  route_table_id = aws_route_table.prod_db.id
}

# ════════════════════════════════════════════════════════════
# VPC OnPrem ROUTE TABLES
# ════════════════════════════════════════════════════════════

# ── Public Route Tables ───────────────────────────────────────
resource "aws_route_table" "onpremise_public" {
  for_each = var.onprem_vpc_ids

  vpc_id = each.value

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.igw_onprem_ids[each.key]
  }

  tags = {
    Name        = "RT-OnPremise-Public-${each.key}"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_route_table_association" "onpremise_public" {
  for_each = var.onprem_public_subnet_ids

  subnet_id      = each.value
  route_table_id = aws_route_table.onpremise_public[each.key].id
}

# ── Private Route Tables ──────────────────────────────────────
# Merged from two separate resources (onpremise_1_private + onpremise_2_private)
# Hospital 1 gets an extra default route via its NAT Gateway; Hospital 2 does not.
resource "aws_route_table" "onpremise_private" {
  for_each = {
    "1" = {
      vpc_id  = var.onprem_vpc_ids["1"]
      eni_id  = var.vpn_appliance_primary_eni_ids["1"]
      has_nat = true
    }
    "2" = {
      vpc_id  = var.onprem_vpc_ids["2"]
      eni_id  = var.vpn_appliance_primary_eni_ids["2"]
      has_nat = false
    }
  }

  vpc_id = each.value.vpc_id

  route {
    cidr_block           = var.vpc_production_cidr
    network_interface_id = each.value.eni_id
  }

  dynamic "route" {
    for_each = each.value.has_nat ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = var.nat_gateway_onprem_1
    }
  }

  tags = {
    Name        = "RT-OnPremise-Private-${each.key}"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_route_table_association" "onpremise_private" {
  for_each = var.onprem_private_subnet_ids

  subnet_id      = each.value
  route_table_id = aws_route_table.onpremise_private[each.key].id
}