###############################################################
# MODULE 07 – SECURITY GROUPS & NACLs
# All security groups are in VPC Production.
# Uses aws_security_group_rule to break circular dependency cycles.
###############################################################

#===============================================================
# Security group for ENI on OnPremise VPC
#===============================================================

# ── Security Groups: VPN Appliance EC2 Instance ───────────────────────────
resource "aws_security_group" "vpn_appliance" {
  for_each = var.onprem_vpc_ids

  name        = "onpremise-vpn-appliance-${each.key}-sg"
  description = "Security Group for VPN Appliance in Hospital ${each.key}"
  vpc_id      = each.value

  # IKE
  ingress {
    description = "IKE"
    from_port   = 500
    to_port     = 500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NAT-T
  ingress {
    description = "NAT-T"
    from_port   = 4500
    to_port     = 4500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ESP (Protocol 50) – workaround: use -1 with from/to = 0
  ingress {
    description = "ESP"
    from_port   = 0
    to_port     = 0
    protocol    = "50"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH from admin IP
  ingress {
    description = "SSH Admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "SG-OnPremise-VPN-Appliance-${each.key}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Security Group for Workstation EC2
resource "aws_security_group" "workstation" {
  for_each = var.onprem_vpc_ids

  name        = "onpremise-workstation-${each.key}-sg"
  description = "Security Group for Workstation in Hospital ${each.key}"
  vpc_id      = each.value

  ingress {
    description = "SSH Admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "SG-OnPremise-Workstation-${each.key}"
    Environment = var.environment
    Project     = var.project_name
  }
}

#===============================================================
# Security group for ENI on Production VPC
#===============================================================

# Security Group for Client VPN ENI
resource "aws_security_group" "client_vpn_endpoint" {
  name        = "clientvpn-endpoint-sg"
  description = "Security Group for Client VPN Endpoint (doctor remote access)"
  vpc_id      = var.vpc_production_id

  ingress {
    description = "OpenVPN UDP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "OpenVPN UDP from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress rules added via aws_security_group_rule to break cycles
  tags = {
    Name        = "SG-ClientVPN-Endpoint"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── 7.2 SG: ALB Internal ─────────────────────────────────────
resource "aws_security_group" "alb_internal" {
  name        = "alb-internal-prod-sg"
  description = "Security Group for Internal ALB in Production"
  vpc_id      = var.vpc_production_id

  ingress {
    description = "HTTPS from Hospital 1"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr_onprem_1, var.cidr_onprem_2, var.cidr_client_vpn]
  }

  ingress {
    description = "HTTP redirect from on-premise and VPN clients"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.cidr_onprem_1, var.cidr_onprem_2, var.cidr_client_vpn]
  }

  ingress {
    description = "HTTP redirect from on-premise and VPN clients"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.cidr_onprem_1, var.cidr_onprem_2, var.cidr_client_vpn]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "SG-ALB-Internal-Prod"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── 7.3 SG: App Server EC2 Instance ───────────────────────────────────
resource "aws_security_group" "app_server" {
  name        = "app-server-prod-sg"
  description = "Security Group for App Server EC2 in Production"
  vpc_id      = var.vpc_production_id

  egress {
    description = "HTTP outbound via NAT GW (updates, patches)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    description = "HTTPS outbound via NAT GW (updates, patches)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTPS outbound via NAT GW (updates, patches)"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ingress from ALB and Bastion, Egress to RDS and VPC Endpoints
  # added via aws_security_group_rule below to break cycles

  tags = {
    Name        = "SG-AppServer-Prod"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── 7.4 SG: RDS Database ─────────────────────────────────────
resource "aws_security_group" "rds" {
  name        = "rds-prod-sg"
  description = "Security Group for RDS Database, inbound from App Server only"
  vpc_id      = var.vpc_production_id

  # Ingress from App Server added via aws_security_group_rule below

  tags = {
    Name        = "SG-RDS-Prod"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── 7.5 SG: Bastion Host ─────────────────────────────────────
resource "aws_security_group" "bastion" {
  name        = "bastion-prod-sg"
  description = "Security Group for Bastion Host in Production Public Subnet"
  vpc_id      = var.vpc_production_id

  ingress {
    description = "SSH from Admin IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip_cidr]
  }

  # Egress to App Server added via aws_security_group_rule below

  tags = {
    Name        = "SG-Bastion-Prod"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── 7.6 SG: VPC Endpoints ────────────────────────────────────
resource "aws_security_group" "vpc_endpoints" {
  name        = "vpc-endpoints-prod-sg"
  description = "Security Group for VPC Endpoints in Production"
  vpc_id      = var.vpc_production_id

  ingress {
    description = "HTTP from VPC Production"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.cidr_vpc_prod]
  }

  ingress {
    description = "HTTPS from VPC Production"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr_vpc_prod]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "SG-VPCEndpoints-Prod"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ══════════════════════════════════════════════════════════════
# Security Group Rules (added separately to break cycles)
# ══════════════════════════════════════════════════════════════

# Client VPN → App Server egress (HTTPS)
resource "aws_security_group_rule" "clientvpn_to_app_https" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.client_vpn_endpoint.id
  source_security_group_id = aws_security_group.app_server.id
  description              = "HTTPS to App Servers"
}

resource "aws_security_group_rule" "clientvpn_to_app_http" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.client_vpn_endpoint.id
  source_security_group_id = aws_security_group.app_server.id
  description              = "HTTP to App Servers"
}

resource "aws_security_group_rule" "clientvpn_to_app_8080" {
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.client_vpn_endpoint.id
  source_security_group_id = aws_security_group.app_server.id
  description              = "App port 8080 to App Servers"
}

# App Server ingress from ALB
resource "aws_security_group_rule" "app_from_alb_8080" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app_server.id
  source_security_group_id = aws_security_group.alb_internal.id
  description              = "HIS App port 8080 from ALB"
}

resource "aws_security_group_rule" "app_from_alb_http" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app_server.id
  source_security_group_id = aws_security_group.alb_internal.id
  description              = "HIS App port 8080 from ALB"
}

resource "aws_security_group_rule" "app_from_alb_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app_server.id
  source_security_group_id = aws_security_group.alb_internal.id
  description              = "HIS App port 8080 from ALB"
}

# App Server ingress from Bastion (SSH)
resource "aws_security_group_rule" "app_from_bastion_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app_server.id
  source_security_group_id = aws_security_group.bastion.id
  description              = "SSH from Bastion"
}

# Bastion egress to App Server (SSH)
resource "aws_security_group_rule" "bastion_to_app_ssh" {
  type                     = "egress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.bastion.id
  source_security_group_id = aws_security_group.app_server.id
  description              = "SSH to App Servers"
}

# App Server egress to RDS MySQL
resource "aws_security_group_rule" "app_to_rds_mysql" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app_server.id
  source_security_group_id = aws_security_group.rds.id
  description              = "MySQL to RDS"
}

# App Server egress to RDS PostgreSQL
resource "aws_security_group_rule" "app_to_rds_pg" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app_server.id
  source_security_group_id = aws_security_group.rds.id
  description              = "PostgreSQL to RDS"
}

# App Server egress to VPC Endpoints (HTTPS)
resource "aws_security_group_rule" "app_to_endpoints" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app_server.id
  source_security_group_id = aws_security_group.vpc_endpoints.id
  description              = "HTTPS to VPC Endpoints (S3, KMS, SSM, Secrets Manager)"
}

# RDS ingress from App Server (MySQL)
resource "aws_security_group_rule" "rds_from_app_mysql" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.app_server.id
  description              = "MySQL from App Server"
}

# RDS ingress from App Server (PostgreSQL)
resource "aws_security_group_rule" "rds_from_app_pg" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.app_server.id
  description              = "PostgreSQL from App Server"
}

# ══════════════════════════════════════════════════════════════
# 7.7 NACL: DB Subnet on Production VPC (double protection)
# ══════════════════════════════════════════════════════════════
resource "aws_network_acl" "prod_db" {
  vpc_id     = var.vpc_production_id
  subnet_ids = [var.subnet_prod_db_az_a_id, var.subnet_prod_db_az_b_id]

  # Inbound: Allow MySQL from App Subnet AZ-A
  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    from_port  = 3306
    to_port    = 3306
    cidr_block = var.subnet_prod_app_az_a_cidr
  }

  # Inbound: Allow MySQL from App Subnet AZ-B
  ingress {
    rule_no    = 110
    action     = "allow"
    protocol   = "tcp"
    from_port  = 3306
    to_port    = 3306
    cidr_block = var.subnet_prod_app_az_b_cidr
  }

  # Inbound: Allow PostgreSQL from App Subnet AZ-A
  ingress {
    rule_no    = 120
    action     = "allow"
    protocol   = "tcp"
    from_port  = 5432
    to_port    = 5432
    cidr_block = var.subnet_prod_app_az_a_cidr
  }

  # Inbound: Allow PostgreSQL from App Subnet AZ-B
  ingress {
    rule_no    = 130
    action     = "allow"
    protocol   = "tcp"
    from_port  = 5432
    to_port    = 5432
    cidr_block = var.subnet_prod_app_az_b_cidr
  }

  # Inbound: Deny all other
  ingress {
    rule_no    = 200
    action     = "deny"
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
  }

  # Outbound: Allow ephemeral ports back to App Subnet AZ-A
  egress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535
    cidr_block = var.subnet_prod_app_az_a_cidr
  }

  # Outbound: Allow ephemeral ports back to App Subnet AZ-B
  egress {
    rule_no    = 110
    action     = "allow"
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535
    cidr_block = var.subnet_prod_app_az_b_cidr
  }

  # Outbound: Deny all other
  egress {
    rule_no    = 200
    action     = "deny"
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name        = "NACL-Prod-DB-Isolated"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ══════════════════════════════════════════════════════════════
# NACL on Production VPC (double protection)
# ══════════════════════════════════════════════════════════════

# NACL for Workstation Subnet
resource "aws_network_acl" "workstation" {
  for_each = {
    "1" = {
      "vpc_id"         = var.onprem_vpc_ids["1"]
      "workstation_id" = var.workstation_subnet_onprem_ids["1"]
      "iot_cidr"       = var.iot_subnet_onprem_cidrs["1"]
      "wifi_cidr"      = var.wifi_subnet_onprem_cidrs["1"]
    }
    "2" = {
      "vpc_id"         = var.onprem_vpc_ids["2"]
      "workstation_id" = var.workstation_subnet_onprem_ids["2"]
      "iot_cidr"       = var.iot_subnet_onprem_cidrs["2"]
      "wifi_cidr"      = var.wifi_subnet_onprem_cidrs["2"]
    }
  }

  vpc_id     = each.value.vpc_id
  subnet_ids = [each.value.workstation_id]

  ingress {
    rule_no    = 100
    action     = "deny"
    protocol   = "tcp"
    from_port  = 0
    to_port    = 0
    cidr_block = each.value.wifi_cidr
  }

  ingress {
    rule_no    = 110
    action     = "allow"
    protocol   = "tcp"
    from_port  = 0
    to_port    = 0
    cidr_block = each.value.iot_cidr
  }

  ingress {
    rule_no    = 120
    action     = "allow"
    protocol   = "tcp"
    from_port  = 22
    to_port    = 22
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    rule_no    = 130
    action     = "allow"
    protocol   = "tcp"
    from_port  = 80
    to_port    = 80
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    rule_no    = 140
    action     = "allow"
    protocol   = "tcp"
    from_port  = 443
    to_port    = 443
    cidr_block = "0.0.0.0/0"
  }

  egress {
    rule_no    = 200
    action     = "allow"
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name        = "NACL-Workstation-Subnet-${each.key}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# NACL for IOT Subnet
resource "aws_network_acl" "iot" {
  for_each = {
    "1" = {
      "vpc_id"           = var.onprem_vpc_ids["1"]
      "iot_id"           = var.iot_subnet_onprem_ids["1"]
      "workstation_cidr" = var.workstation_subnet_onprem_cidrs["1"]
      "wifi_cidr"        = var.wifi_subnet_onprem_cidrs["1"]
    }
    "2" = {
      "vpc_id"           = var.onprem_vpc_ids["2"]
      "iot_id"           = var.iot_subnet_onprem_ids["2"]
      "workstation_cidr" = var.workstation_subnet_onprem_cidrs["2"]
      "wifi_cidr"        = var.wifi_subnet_onprem_cidrs["2"]
    }
  }

  vpc_id     = each.value.vpc_id
  subnet_ids = [each.value.iot_id]  # fixed: was each.value.workstation_id

  ingress {
    rule_no    = 100
    action     = "deny"
    protocol   = "tcp"
    from_port  = 0
    to_port    = 0
    cidr_block = each.value.wifi_cidr
  }

  ingress {
    rule_no    = 110
    action     = "allow"
    protocol   = "tcp"
    from_port  = 0
    to_port    = 0
    cidr_block = each.value.workstation_cidr
  }

  ingress {
    rule_no    = 120
    action     = "allow"
    protocol   = "tcp"
    from_port  = 22
    to_port    = 22
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    rule_no    = 130
    action     = "allow"
    protocol   = "tcp"
    from_port  = 80
    to_port    = 80
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    rule_no    = 140
    action     = "allow"
    protocol   = "tcp"
    from_port  = 443
    to_port    = 443
    cidr_block = "0.0.0.0/0"
  }

  egress {
    rule_no    = 200
    action     = "allow"
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name        = "NACL-IOT-Subnet-${each.key}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# NACL for Wifi Subnet
resource "aws_network_acl" "wifi" {
  for_each = {
    "1" = {
      "vpc_id"           = var.onprem_vpc_ids["1"]
      "wifi_id"          = var.wifi_subnet_onprem_ids["1"]
      "iot_cidr"         = var.iot_subnet_onprem_cidrs["1"]
      "workstation_cidr" = var.workstation_subnet_onprem_cidrs["1"]
    }
    "2" = {
      "vpc_id"           = var.onprem_vpc_ids["2"]
      "wifi_id"          = var.wifi_subnet_onprem_ids["2"]
      "iot_cidr"         = var.iot_subnet_onprem_cidrs["2"]
      "workstation_cidr" = var.workstation_subnet_onprem_cidrs["2"]
    }
  }

  vpc_id     = each.value.vpc_id
  subnet_ids = [each.value.wifi_id]  # fixed: was each.value.workstation_id

  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
  }

  egress {
    rule_no    = 100
    action     = "deny"
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = each.value.iot_cidr
  }

  egress {
    rule_no    = 110
    action     = "deny"
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = each.value.workstation_cidr
  }

  egress {
    rule_no    = 200
    action     = "allow"
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name        = "NACL-Wifi-Subnet-${each.key}"
    Environment = var.environment
    Project     = var.project_name
  }
}
