###############################################################
# MODULE 01 – VPC ONPREMISE (Simulate 2 Hospitals)
# Creates 2 independent VPCs simulating on-premise hospital networks
# Each VPC has: public/private subnets, IGW, route tables, EIP, SG
###############################################################

# ── Hospital VPCs ─────────────────────────────────────────────
resource "aws_vpc" "onpremise" {
  for_each = {
    "1" = { cidr = var.vpc_cidr_onprem_1, name = "VPC-OnPremise-1" }
    "2" = { cidr = var.vpc_cidr_onprem_2, name = "VPC-OnPremise-2" }
  }

  cidr_block           = each.value.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = each.value.name
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── Internet Gateways ─────────────────────────────────────────
resource "aws_internet_gateway" "onpremise" {
  for_each = {
    "1" = aws_vpc.onpremise["1"].id
    "2" = aws_vpc.onpremise["2"].id
  }

  vpc_id = each.value

  tags = {
    Name        = "IGW-OnPremise-${each.key}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── Public Subnets ────────────────────────────────────────────
resource "aws_subnet" "onpremise_public" {
  for_each = {
    "1" = { cidr = var.public_subnet_cidr_onprem_1, vpc_key = "1" }
    "2" = { cidr = var.public_subnet_cidr_onprem_2, vpc_key = "2" }
  }

  vpc_id                  = aws_vpc.onpremise[each.value.vpc_key].id
  cidr_block              = each.value.cidr
  availability_zone       = var.az_a
  map_public_ip_on_launch = true

  tags = {
    Name        = "Subnet-OnPremise-Public-${each.key}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── Private Subnets ───────────────────────────────────────────
resource "aws_subnet" "onpremise_private" {
  for_each = {
    "Workstation-1" = { cidr = var.workstation_subnet_cidr_onprem_1, vpc_key = "1" }
    "IOT-1" = { cidr = var.iot_subnet_cidr_onprem_1, vpc_key = "1" }
    "Wifi-1" = { cidr = var.wifi_subnet_cidr_onprem_1, vpc_key = "1" }
    "Workstation-2" = { cidr = var.workstation_subnet_cidr_onprem_2, vpc_key = "2" }
    "IOT-2" = { cidr = var.iot_subnet_cidr_onprem_2, vpc_key = "2" }
    "Wifi-2" = { cidr = var.wifi_subnet_cidr_onprem_2, vpc_key = "2" }
  }

  vpc_id                  = aws_vpc.onpremise[each.value.vpc_key].id
  cidr_block              = each.value.cidr
  availability_zone       = var.az_a
  map_public_ip_on_launch = false

  tags = {
    Name        = "Subnet-OnPremise-${each.key}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── Elastic IPs for VPN Appliances ───────────────────────────
resource "aws_eip" "vpn_appliance" {
  for_each = { "1" = {}, "2" = {} }
  domain   = "vpc"

  tags = {
    Name        = "EIP-OnPremise-VPN-${each.key}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Elastic IPs for NAT at OnPremise-1
resource "aws_eip" "nat_on_premise_1" {
  domain = "vpc"

  tags = {
    Name        = "EIP-NatGW-OnPrem-1"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_nat_gateway" "nat_on_premise_1" {
  allocation_id     = aws_eip.nat_on_premise_1.id
  subnet_id         = aws_subnet.onpremise_public["1"].id
  connectivity_type = "public"

  depends_on = [aws_internet_gateway.onpremise]

  tags = {
    Name        = "NatGW-Prod-OnPrem-1"
    Environment = var.environment
    Project     = var.project_name
  }
}

