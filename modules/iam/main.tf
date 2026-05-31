###############################################################
# MODULE 15 – IAM ROLES & POLICIES
# Creates IAM roles for EC2 instances and services
###############################################################

# ── 15.1 IAM Role: EC2 App Server ──────────────────────────
resource "aws_iam_role" "ec2_app_server" {
  name = "role-ec2-app-server"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "IAM-Role-EC2-AppServer"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "app_server_ssm" {
  role       = aws_iam_role.ec2_app_server.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "app_server_custom" {
  name        = "policy-ec2-app-server-custom"
  description = "Custom policy for App Server: S3, KMS, Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3MedicalData"
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
        Resource = [
          "arn:aws:s3:::${var.s3_medical_data_bucket}",
          "arn:aws:s3:::${var.s3_medical_data_bucket}/*"
        ]
      },
      {
        Sid      = "AllowKMSS3"
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:GenerateDataKey", "kms:DescribeKey"]
        Resource = [var.kms_key_s3_arn]
      },
      {
        Sid      = "AllowSecretsManager"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = ["arn:aws:secretsmanager:${var.aws_region}:*:secret:hospital/prod/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "app_server_custom" {
  role       = aws_iam_role.ec2_app_server.name
  policy_arn = aws_iam_policy.app_server_custom.arn
}

resource "aws_iam_instance_profile" "ec2_app_server" {
  name = "profile-ec2-app-server"
  role = aws_iam_role.ec2_app_server.name
}

# ── 15.2 IAM Role: EC2 VPN Appliance ────────────────────────
resource "aws_iam_role" "ec2_vpn_appliance" {
  name = "role-ec2-vpn-appliance"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "IAM-Role-EC2-VPNAppliance"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "vpn_appliance_ssm" {
  role       = aws_iam_role.ec2_vpn_appliance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_vpn_appliance" {
  name = "profile-ec2-vpn-appliance"
  role = aws_iam_role.ec2_vpn_appliance.name
}

# ── 15.3 IAM Role: EC2 Bastion & Management ─────────────────
resource "aws_iam_role" "ec2_bastion" {
  name = "role-ec2-bastion"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "IAM-Role-EC2-Bastion"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.ec2_bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_bastion" {
  name = "profile-ec2-bastion"
  role = aws_iam_role.ec2_bastion.name
}

# ── 15.4 IAM Role: CloudTrail → S3 ──────────────────────────
resource "aws_iam_role" "cloudtrail_s3" {
  name = "role-cloudtrail-s3"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "cloudtrail.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "IAM-Role-CloudTrail-S3"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_policy" "cloudtrail_s3" {
  name        = "policy-cloudtrail-s3"
  description = "Allow CloudTrail to write logs to S3 and CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3Write"
        Effect = "Allow"
        Action = ["s3:PutObject"]
        Resource = [
          "arn:aws:s3:::${var.s3_cloudtrail_bucket}/*"
        ]
      },
      {
        Sid    = "AllowCWLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = ["arn:aws:logs:*:*:*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudtrail_s3" {
  role       = aws_iam_role.cloudtrail_s3.name
  policy_arn = aws_iam_policy.cloudtrail_s3.arn
}

# ── 15.5 IAM Role: VPC Flow Logs → CloudWatch ───────────────
resource "aws_iam_role" "vpc_flowlogs_cw" {
  name = "role-vpc-flowlogs-cw"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "IAM-Role-VPCFlowLogs-CW"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_policy" "vpc_flowlogs_cw" {
  name        = "policy-vpc-flowlogs-cw"
  description = "Allow VPC Flow Logs to write to CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCWLogs"
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = ["*"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "vpc_flowlogs_cw" {
  role       = aws_iam_role.vpc_flowlogs_cw.name
  policy_arn = aws_iam_policy.vpc_flowlogs_cw.arn
}
