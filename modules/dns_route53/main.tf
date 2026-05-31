###############################################################
# MODULE 15 – DNS ROUTE 53
# Private Hosted Zone for hospital.internal
# Associated only with VPC Production (single VPC in v2).
###############################################################

# ── 15.1 Private Hosted Zone ──────────────────────────────────
resource "aws_route53_zone" "hospital_internal" {
  name    = var.private_zone_name
  comment = "Internal DNS for Hospital HIS System"

  vpc {
    vpc_id = var.vpc_production_id
  }

  tags = {
    Name        = "PrivateZone-hospital.internal"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── 15.2 DNS Records ──────────────────────────────────────────

# his-app.hospital.internal → Internal ALB (ALIAS)
resource "aws_route53_record" "his_app" {
  zone_id = aws_route53_zone.hospital_internal.zone_id
  name    = "his-app.${var.private_zone_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# db.hospital.internal → RDS Endpoint (CNAME)
resource "aws_route53_record" "db" {
  zone_id = aws_route53_zone.hospital_internal.zone_id
  name    = "db.${var.private_zone_name}"
  type    = "CNAME"
  ttl     = 300
  records = [var.rds_address]
}

# ── 15.3 Health Check for HIS ALB Endpoint ───────────────────
resource "aws_route53_health_check" "his_endpoint" {
  fqdn              = "his-app.${var.private_zone_name}"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30

  cloudwatch_alarm_name           = "alarm-his-healthcheck"
  cloudwatch_alarm_region         = var.aws_region
  # insufficient_data_health_status = "Unhealthy"

  tags = {
    Name        = "HC-HIS-ALB-Production"
    Environment = var.environment
    Project     = var.project_name
  }
}
