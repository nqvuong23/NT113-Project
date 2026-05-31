###############################################################
# MODULE 13 – STORAGE S3
# Creates 4 S3 buckets + DynamoDB table for Terraform lock:
#   1. Medical Data (X-ray, EMR files)
#   2. CloudTrail Logs
#   3. Terraform State
#   4. ALB Access Logs
#   5. DynamoDB: Terraform State Lock
###############################################################

data "aws_caller_identity" "current" {}

# ── 13.1 S3 Bucket: Medical Data ───────────────────────────
resource "aws_s3_bucket" "medical_data" {
  bucket        = var.medical_data_bucket_name
  force_destroy = true

  tags = {
    Name        = "S3-Hospital-MedicalData"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_s3_bucket_versioning" "medical_data" {
  bucket = aws_s3_bucket.medical_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "medical_data" {
  bucket = aws_s3_bucket.medical_data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_s3_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "medical_data" {
  bucket                  = aws_s3_bucket.medical_data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "medical_data" {
  bucket = aws_s3_bucket.medical_data.id

  rule {
    id     = "transition-to-glacier"
    status = "Enabled"
    transition {
      days          = 365
      storage_class = "GLACIER"
    }
  }

  rule {
    id     = "expire-noncurrent"
    status = "Enabled"
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# Deny unencrypted uploads bucket policy
resource "aws_s3_bucket_policy" "medical_data" {
  bucket = aws_s3_bucket.medical_data.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyUnencryptedUploads"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.medical_data.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      },
      {
        Sid       = "DenyNonHTTPS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.medical_data.arn,
          "${aws_s3_bucket.medical_data.arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      }
    ]
  })
}

# ── 13.2 S3 Bucket: CloudTrail Logs ────────────────────────
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket        = var.cloudtrail_bucket_name
  force_destroy = true

  tags = {
    Name        = "S3-Hospital-CloudTrailLogs"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_s3_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket                  = aws_s3_bucket.cloudtrail_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    id     = "transition-to-glacier"
    status = "Enabled"
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }

  rule {
    id     = "expire-after-7-years"
    status = "Enabled"
    expiration {
      days = 2555
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# ── 13.4 S3 Bucket: ALB Access Logs ────────────────────────
resource "aws_s3_bucket" "alb_logs" {
  bucket        = var.alb_logs_bucket_name
  force_destroy = true

  tags = {
    Name        = "S3-Hospital-ALBLogs"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket                  = aws_s3_bucket.alb_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "expire-after-90-days"
    status = "Enabled"
    expiration {
      days = 90
    }
  }
}

# ELB service account needs permission to write ALB logs
resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowELBServiceAccount"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::114774131450:root" # ELB service account for ap-southeast-1
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/*"
      },
      {
        Sid    = "AllowDeliveryLogs"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid    = "AllowGetBucketAcl"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.alb_logs.arn
      }
    ]
  })
}


