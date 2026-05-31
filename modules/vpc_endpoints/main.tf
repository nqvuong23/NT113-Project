###############################################################
# MODULE 16 – VPC ENDPOINTS (AWS PrivateLink)
# Gateway: S3, DynamoDB. Interface: KMS, SecretsManager, SSM, Logs
###############################################################

# ── 16.1 Gateway Endpoint: S3 (VPC Production) ───────────────
resource "aws_vpc_endpoint" "s3_prod" {
  vpc_id            = var.vpc_production_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [var.rt_prod_app_az_a_id, var.rt_prod_app_az_b_id]

  tags = {
    Name        = "VPCEndpoint-S3-Prod"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── 16.2 Gateway Endpoint: DynamoDB (VPC Production) ─────────
resource "aws_vpc_endpoint" "dynamodb_prod" {
  vpc_id            = var.vpc_production_id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [var.rt_prod_app_az_a_id, var.rt_prod_app_az_b_id]

  tags = {
    Name        = "VPCEndpoint-DynamoDB-Prod"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── 16.3 Interface Endpoint: KMS (VPC Production) ────────────
resource "aws_vpc_endpoint" "kms_prod" {
  vpc_id              = var.vpc_production_id
  service_name        = "com.amazonaws.${var.aws_region}.kms"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_prod_app_az_a_id, var.subnet_prod_app_az_b_id]
  security_group_ids  = [var.sg_vpc_endpoints_id]
  private_dns_enabled = true

  tags = {
    Name        = "VPCEndpoint-KMS-Prod"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── 16.4 Interface Endpoint: Secrets Manager (VPC Production) ─
resource "aws_vpc_endpoint" "secretsmanager_prod" {
  vpc_id              = var.vpc_production_id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_prod_app_az_a_id, var.subnet_prod_app_az_b_id]
  security_group_ids  = [var.sg_vpc_endpoints_id]
  private_dns_enabled = true

  tags = {
    Name        = "VPCEndpoint-SecretsManager-Prod"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── 16.5 Interface Endpoints: SSM (Production) ───────────────
resource "aws_vpc_endpoint" "ssm_prod" {
  vpc_id              = var.vpc_production_id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_prod_app_az_a_id, var.subnet_prod_app_az_b_id]
  security_group_ids  = [var.sg_vpc_endpoints_id]
  private_dns_enabled = true

  tags = {
    Name        = "VPCEndpoint-SSM-Prod"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_vpc_endpoint" "ssmmessages_prod" {
  vpc_id              = var.vpc_production_id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_prod_app_az_a_id, var.subnet_prod_app_az_b_id]
  security_group_ids  = [var.sg_vpc_endpoints_id]
  private_dns_enabled = true

  tags = {
    Name        = "VPCEndpoint-SSMMessages-Prod"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_vpc_endpoint" "ec2messages_prod" {
  vpc_id              = var.vpc_production_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_prod_app_az_a_id, var.subnet_prod_app_az_b_id]
  security_group_ids  = [var.sg_vpc_endpoints_id]
  private_dns_enabled = true

  tags = {
    Name        = "VPCEndpoint-EC2Messages-Prod"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── 16.6 Interface Endpoint: CloudWatch Logs (VPC Production) ─
resource "aws_vpc_endpoint" "logs_prod" {
  vpc_id              = var.vpc_production_id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_prod_app_az_a_id, var.subnet_prod_app_az_b_id]
  security_group_ids  = [var.sg_vpc_endpoints_id]
  private_dns_enabled = true

  tags = {
    Name        = "VPCEndpoint-Logs-Prod"
    Environment = var.environment
    Project     = var.project_name
  }
}
