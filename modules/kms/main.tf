###############################################################
# MODULE 14 – KMS KEYS
# Creates 3 KMS Customer Managed Keys + Aliases:
#   1. General (EBS, CloudWatch Logs, SNS)
#   2. RDS Database encryption
#   3. S3 Medical Data encryption
###############################################################

data "aws_caller_identity" "current" {}

# ── 14.1 KMS Key: General (EBS, Logs, SNS) ─────────────────
resource "aws_kms_key" "general" {
  description             = "Hospital General Encryption Key"
  deletion_window_in_days = var.kms_deletion_window
  enable_key_rotation     = true
  key_usage               = "ENCRYPT_DECRYPT"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow SNS"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "KMS-Hospital-General"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_kms_alias" "general" {
  name          = "alias/hospital-general"
  target_key_id = aws_kms_key.general.key_id
}

# ── 14.2 KMS Key: RDS Database ─────────────────────────────
resource "aws_kms_key" "rds" {
  description             = "Hospital RDS Encryption Key"
  deletion_window_in_days = var.kms_deletion_window
  enable_key_rotation     = true
  key_usage               = "ENCRYPT_DECRYPT"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow RDS Service"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "KMS-Hospital-RDS"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/hospital-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# ── 14.3 KMS Key: S3 Medical Data ──────────────────────────
resource "aws_kms_key" "s3" {
  description             = "Hospital S3 Medical Data Encryption Key"
  deletion_window_in_days = var.kms_deletion_window
  enable_key_rotation     = true
  key_usage               = "ENCRYPT_DECRYPT"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow S3 Service"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow CloudTrail"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "KMS-Hospital-S3"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_kms_alias" "s3" {
  name          = "alias/hospital-s3"
  target_key_id = aws_kms_key.s3.key_id
}
