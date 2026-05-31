###############################################################
# MODULE 16 – MONITORING
# CloudTrail, CloudWatch Log Groups, VPC Flow Logs (Production only),
# SNS Alerts, CloudWatch Alarms, Dashboard
###############################################################

# ── 16.2 CloudWatch Log Groups ────────────────────────────────
resource "aws_cloudwatch_log_group" "vpc_flowlogs_production" {
  name              = "/hospital/vpc-flowlogs/production"
  retention_in_days = var.flowlogs_retention_days
  kms_key_id        = var.kms_key_general_arn

  tags = {
    Name        = "CWLogs-FlowLogs-Production"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_log_group" "vpc_flowlogs_onpremise_1" {
  name              = "/hospital/vpc-flowlogs/onpremise-1"
  retention_in_days = 30
  kms_key_id        = var.kms_key_general_arn

  tags = {
    Name        = "CWLogs-FlowLogs-OnPremise-1"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_log_group" "vpc_flowlogs_onpremise_2" {
  name              = "/hospital/vpc-flowlogs/onpremise-2"
  retention_in_days = 30
  kms_key_id        = var.kms_key_general_arn

  tags = {
    Name        = "CWLogs-FlowLogs-OnPremise-2"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/hospital/cloudtrail"
  retention_in_days = var.cloudtrail_log_retention_days
  kms_key_id        = var.kms_key_general_arn

  tags = {
    Name        = "CWLogs-CloudTrail"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_log_group" "appserver" {
  name              = "/hospital/ec2/appserver"
  retention_in_days = var.appserver_log_retention_days
  kms_key_id        = var.kms_key_general_arn

  tags = {
    Name        = "CWLogs-AppServer"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── 16.1 CloudTrail (Multi-Region) ───────────────────────────
resource "aws_cloudtrail" "hospital_audit" {
  name                          = "hospital-audit-trail"
  s3_bucket_name                = var.cloudtrail_bucket_name
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  include_global_service_events = true
  kms_key_id                    = var.kms_key_s3_arn
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn     = var.cloudtrail_role_arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
  }

  tags = {
    Name        = "CloudTrail-Hospital-Audit"
    Environment = var.environment
    Project     = var.project_name
  }

  depends_on = [aws_cloudwatch_log_group.cloudtrail]
}

# ── 16.3 VPC Flow Logs ────────────────────────────────────────
locals {
  extended_log_format = "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status} $${pkt-srcaddr} $${pkt-dstaddr}"
}

# Flow Logs for VPC Production (required)
resource "aws_flow_log" "production" {
  traffic_type         = "ALL"
  vpc_id               = var.vpc_production_id
  iam_role_arn         = var.vpc_flowlogs_role_arn
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flowlogs_production.arn
  log_format           = local.extended_log_format

  tags = {
    Name        = "FlowLog-VPC-Production"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── 16.4 SNS Topic ────────────────────────────────────────────
resource "aws_sns_topic" "hospital_alerts" {
  name              = "hospital-it-alerts"
  kms_master_key_id = var.kms_key_general_arn

  tags = {
    Name        = "SNS-Hospital-Alerts"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.hospital_alerts.arn
  protocol  = "email"
  endpoint  = var.admin_email
}

# ── 16.5 CloudWatch Alarms ────────────────────────────────────

# Alarm 1: VPN Tunnel Down – Hospital 1
resource "aws_cloudwatch_metric_alarm" "vpn_tunnel_down_h1" {
  alarm_name          = "alarm-vpn-down-hospital1-t1"
  alarm_description   = "VPN Tunnel 1 for Hospital 1 is down"
  namespace           = "AWS/VPN"
  metric_name         = "TunnelState"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 3
  comparison_operator = "LessThanThreshold"
  threshold           = 1
  treat_missing_data  = "breaching"

  dimensions = {
    VpnId = var.vpn_connection_id_1
  }

  alarm_actions = [aws_sns_topic.hospital_alerts.arn]
  ok_actions    = [aws_sns_topic.hospital_alerts.arn]

  tags = {
    Name        = "Alarm-VPN-Tunnel-Hospital1"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Alarm 2: VPN Tunnel Down – Hospital 2
resource "aws_cloudwatch_metric_alarm" "vpn_tunnel_down_h2" {
  alarm_name          = "alarm-vpn-down-hospital2-t1"
  alarm_description   = "VPN Tunnel 1 for Hospital 2 is down"
  namespace           = "AWS/VPN"
  metric_name         = "TunnelState"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 3
  comparison_operator = "LessThanThreshold"
  threshold           = 1
  treat_missing_data  = "breaching"

  dimensions = {
    VpnId = var.vpn_connection_id_2
  }

  alarm_actions = [aws_sns_topic.hospital_alerts.arn]
  ok_actions    = [aws_sns_topic.hospital_alerts.arn]

  tags = {
    Name        = "Alarm-VPN-Tunnel-Hospital2"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Alarm 3: RDS CPU > 80%
resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name          = "alarm-rds-high-cpu"
  alarm_description   = "RDS CPU utilization exceeded 80%"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  comparison_operator = "GreaterThanThreshold"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.rds_identifier
  }

  alarm_actions = [aws_sns_topic.hospital_alerts.arn]

  tags = {
    Name        = "Alarm-RDS-HighCPU"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Alarm 4: ALB Unhealthy Hosts > 0
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "alarm-alb-unhealthy-hosts"
  alarm_description   = "ALB has unhealthy target hosts"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.tg_arn_suffix
  }

  alarm_actions = [aws_sns_topic.hospital_alerts.arn]

  tags = {
    Name        = "Alarm-ALB-UnhealthyHosts"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Alarm 5a: EC2 App Server AZ-A CPU > 85%
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_az_a" {
  alarm_name          = "alarm-ec2-appserver-az-a-high-cpu"
  alarm_description   = "App Server AZ-A CPU > 85%"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  comparison_operator = "GreaterThanThreshold"
  threshold           = 85
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = var.app_server_az_a_id
  }

  alarm_actions = [aws_sns_topic.hospital_alerts.arn]

  tags = {
    Name        = "Alarm-EC2-AppServer-AZ-A-HighCPU"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Alarm 5b: EC2 App Server AZ-B CPU > 85%
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_az_b" {
  alarm_name          = "alarm-ec2-appserver-az-b-high-cpu"
  alarm_description   = "App Server AZ-B CPU > 85%"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  comparison_operator = "GreaterThanThreshold"
  threshold           = 85
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = var.app_server_az_b_id
  }

  alarm_actions = [aws_sns_topic.hospital_alerts.arn]

  tags = {
    Name        = "Alarm-EC2-AppServer-AZ-B-HighCPU"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Alarm 6: RDS Free Storage < 10 GB
resource "aws_cloudwatch_metric_alarm" "rds_low_storage" {
  alarm_name          = "alarm-rds-low-storage"
  alarm_description   = "RDS free storage space < 10 GB"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  statistic           = "Minimum"
  period              = 300
  evaluation_periods  = 2
  comparison_operator = "LessThanThreshold"
  threshold           = 10737418240 # 10 GB in bytes
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.rds_identifier
  }

  alarm_actions = [aws_sns_topic.hospital_alerts.arn]

  tags = {
    Name        = "Alarm-RDS-LowStorage"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Alarm 7: RDS DB Connections > 80
resource "aws_cloudwatch_metric_alarm" "rds_high_connections" {
  alarm_name          = "alarm-rds-high-connections"
  alarm_description   = "RDS database connections exceeded 80"
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  comparison_operator = "GreaterThanThreshold"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.rds_identifier
  }

  alarm_actions = [aws_sns_topic.hospital_alerts.arn]

  tags = {
    Name        = "Alarm-RDS-HighConnections"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Alarm 8: Route 53 Health Check Failed
resource "aws_cloudwatch_metric_alarm" "his_endpoint_down" {
  alarm_name          = "alarm-his-endpoint-down"
  alarm_description   = "HIS App endpoint health check failed"
  namespace           = "AWS/Route53"
  metric_name         = "HealthCheckStatus"
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 2
  comparison_operator = "LessThanThreshold"
  threshold           = 1
  treat_missing_data  = "breaching"

  dimensions = {
    HealthCheckId = var.route53_health_check_id
  }

  alarm_actions = [aws_sns_topic.hospital_alerts.arn]

  tags = {
    Name        = "Alarm-HIS-EndpointDown"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── 16.6 CloudWatch Dashboard ─────────────────────────────────
resource "aws_cloudwatch_dashboard" "hospital_ops" {
  dashboard_name = "Hospital-IT-Operations"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 8
        height = 6
        properties = {
          title   = "VPN Tunnel States (2 Hospitals)"
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/VPN", "TunnelState", "VpnId", var.vpn_connection_id_1, { "label" = "Hospital 1" }],
            ["AWS/VPN", "TunnelState", "VpnId", var.vpn_connection_id_2, { "label" = "Hospital 2" }]
          ]
          period = 60
          region = var.aws_region
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 0
        width  = 8
        height = 6
        properties = {
          title = "ALB Request Count & Latency"
          view  = "timeSeries"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix]
          ]
          period = 60
          region = var.aws_region
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 0
        width  = 8
        height = 6
        properties = {
          title = "ALB Healthy/Unhealthy Hosts"
          view  = "timeSeries"
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", var.alb_arn_suffix, "TargetGroup", var.tg_arn_suffix],
            ["AWS/ApplicationELB", "UnHealthyHostCount", "LoadBalancer", var.alb_arn_suffix, "TargetGroup", var.tg_arn_suffix]
          ]
          period = 60
          region = var.aws_region
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title = "EC2 App Server CPU Utilization"
          view  = "timeSeries"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", var.app_server_az_a_id, { "label" = "AZ-A" }],
            ["AWS/EC2", "CPUUtilization", "InstanceId", var.app_server_az_b_id, { "label" = "AZ-B" }]
          ]
          period = 60
          region = var.aws_region
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title = "RDS CPU, Connections & Free Storage"
          view  = "timeSeries"
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_identifier],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.rds_identifier],
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", var.rds_identifier]
          ]
          period = 60
          region = var.aws_region
        }
      }
    ]
  })
}
