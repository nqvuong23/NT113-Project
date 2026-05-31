###############################################################
# MODULE 02 – VPC PRODUCTION (10.0.4.0/22)
# The SINGLE AWS VPC for all production workloads.
# Contains 10 subnets across 2 AZs:
#   TGW (×2), ClientVPN (×2), Public/NAT (×2), App (×2), DB (×2)
# Also hosts Internet Gateway and 2× NAT Gateway for outbound traffic.
###############################################################

# ── 2.1 VPC Production ───────────────────────────────────────
resource "aws_vpc" "production" {
  cidr_block           = var.cidr_vpc_prod
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "VPC-Production"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── 2.2 Internet Gateway (for NAT GW outbound – no inbound public) ──
resource "aws_internet_gateway" "prod" {
  vpc_id = aws_vpc.production.id

  tags = {
    Name        = "IGW-Production"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── 2.3 Subnets (10 total – 5 types × 2 AZs) ─────────────────

# TGW Attachment Subnets (ENI for Transit Gateway)
resource "aws_subnet" "prod_tgw_az_a" {
  vpc_id                  = aws_vpc.production.id
  cidr_block              = var.subnet_prod_tgw_az_a
  availability_zone       = var.az_a
  map_public_ip_on_launch = false

  tags = {
    Name        = "Subnet-Prod-TGW-AZ-A"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_subnet" "prod_tgw_az_b" {
  vpc_id                  = aws_vpc.production.id
  cidr_block              = var.subnet_prod_tgw_az_b
  availability_zone       = var.az_b
  map_public_ip_on_launch = false

  tags = {
    Name        = "Subnet-Prod-TGW-AZ-B"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Client VPN Subnets (ENI for Client VPN Endpoint – min /27 required)
resource "aws_subnet" "prod_clientvpn_az_a" {
  vpc_id                  = aws_vpc.production.id
  cidr_block              = var.subnet_prod_clientvpn_az_a
  availability_zone       = var.az_a
  map_public_ip_on_launch = false

  tags = {
    Name        = "Subnet-Prod-ClientVPN-AZ-A"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_subnet" "prod_clientvpn_az_b" {
  vpc_id                  = aws_vpc.production.id
  cidr_block              = var.subnet_prod_clientvpn_az_b
  availability_zone       = var.az_b
  map_public_ip_on_launch = false

  tags = {
    Name        = "Subnet-Prod-ClientVPN-AZ-B"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Public Subnets (NAT Gateway placement – no public IPs on instances)
resource "aws_subnet" "prod_public_az_a" {
  vpc_id                  = aws_vpc.production.id
  cidr_block              = var.subnet_prod_public_az_a
  availability_zone       = var.az_a
  map_public_ip_on_launch = false

  tags = {
    Name        = "Subnet-Prod-Public-AZ-A"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_subnet" "prod_public_az_b" {
  vpc_id                  = aws_vpc.production.id
  cidr_block              = var.subnet_prod_public_az_b
  availability_zone       = var.az_b
  map_public_ip_on_launch = false

  tags = {
    Name        = "Subnet-Prod-Public-AZ-B"
    Environment = var.environment
    Project     = var.project_name
  }
}

# App Subnets (EC2 App Server HIS, Internal ALB)
resource "aws_subnet" "prod_app_az_a" {
  vpc_id                  = aws_vpc.production.id
  cidr_block              = var.subnet_prod_app_az_a
  availability_zone       = var.az_a
  map_public_ip_on_launch = false

  tags = {
    Name        = "Subnet-Prod-App-AZ-A"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_subnet" "prod_app_az_b" {
  vpc_id                  = aws_vpc.production.id
  cidr_block              = var.subnet_prod_app_az_b
  availability_zone       = var.az_b
  map_public_ip_on_launch = false

  tags = {
    Name        = "Subnet-Prod-App-AZ-B"
    Environment = var.environment
    Project     = var.project_name
  }
}

# DB Subnets (RDS – Isolated)
resource "aws_subnet" "prod_db_az_a" {
  vpc_id                  = aws_vpc.production.id
  cidr_block              = var.subnet_prod_db_az_a
  availability_zone       = var.az_a
  map_public_ip_on_launch = false

  tags = {
    Name        = "Subnet-Prod-DB-AZ-A"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_subnet" "prod_db_az_b" {
  vpc_id                  = aws_vpc.production.id
  cidr_block              = var.subnet_prod_db_az_b
  availability_zone       = var.az_b
  map_public_ip_on_launch = false

  tags = {
    Name        = "Subnet-Prod-DB-AZ-B"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── 2.4 Elastic IPs for NAT Gateways ─────────────────────────
resource "aws_eip" "nat_az_a" {
  domain = "vpc"

  tags = {
    Name        = "EIP-NatGW-Prod-AZ-A"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_eip" "nat_az_b" {
  domain = "vpc"

  tags = {
    Name        = "EIP-NatGW-Prod-AZ-B"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── 2.5 NAT Gateways (HA – one per AZ) ───────────────────────
resource "aws_nat_gateway" "prod_az_a" {
  allocation_id     = aws_eip.nat_az_a.id
  subnet_id         = aws_subnet.prod_public_az_a.id
  connectivity_type = "public"

  depends_on = [aws_internet_gateway.prod]

  tags = {
    Name        = "NatGW-Prod-AZ-A"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_nat_gateway" "prod_az_b" {
  allocation_id     = aws_eip.nat_az_b.id
  subnet_id         = aws_subnet.prod_public_az_b.id
  connectivity_type = "public"

  depends_on = [aws_internet_gateway.prod]

  tags = {
    Name        = "NatGW-Prod-AZ-B"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_db_subnet_group" "prod" {
  name = "main"

  subnet_ids = [aws_subnet.prod_db_az_a.id, aws_subnet.prod_db_az_b.id]
}
