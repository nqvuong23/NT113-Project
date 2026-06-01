###############################################################
# MODULE 12 – DATABASE RDS
# MySQL RDS Multi-AZ with encryption, backup, Secrets Manager
###############################################################

# ── 12.1 RDS Parameter Group ──────────────────────────────────
resource "aws_db_parameter_group" "hospital" {
  name        = "hospital-prod-pg"
  family      = var.db_parameter_group_family
  description = "Hospital Production RDS Parameter Group"

  parameter {
    name  = "require_secure_transport"
    value = "1"
  }

  tags = {
    Name        = "ParamGroup-Hospital-Prod"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── 12.3 Secrets Manager – DB Credentials ────────────────────
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "hospital/prod/db-credentials-v2"
  kms_key_id  = var.kms_key_rds_arn
  description = "Hospital Production RDS master credentials"

  tags = {
    Name        = "Secret-Hospital-DB"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })
}

# ── 12.2 RDS Instance (Multi-AZ) ─────────────────────────────
resource "aws_db_instance" "hospital_prod" {
  identifier = "hospital-prod-db"

  engine         = var.db_engine
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = var.kms_key_rds_arn

  multi_az = true

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [var.sg_rds_id]
  parameter_group_name   = aws_db_parameter_group.hospital.name

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  backup_retention_period = var.db_backup_retention_days
  backup_window           = "02:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:06:00"

  deletion_protection       = false
  skip_final_snapshot       = false
  final_snapshot_identifier = "hospital-prod-db-final"

  # performance_insights_enabled          = true
  # performance_insights_kms_key_id       = var.kms_key_rds_arn
  # performance_insights_retention_period = 7

  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = true

  tags = {
    Name        = "RDS-Hospital-Production"
    Environment = var.environment
    Project     = var.project_name
  }

  depends_on = [aws_secretsmanager_secret_version.db_credentials]
}
