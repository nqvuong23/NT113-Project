###############################################################
# MODULE 11 – INTERNAL APPLICATION LOAD BALANCER
# Internal ALB for HIS/EMR app in VPC Production
###############################################################

# ── 11.1 Internal ALB ─────────────────────────────────────────
resource "aws_lb" "internal_prod" {
  name               = "alb-internal-prod"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.sg_alb_internal_id]
  subnets            = [var.subnet_prod_app_az_a_id, var.subnet_prod_app_az_b_id]

  enable_deletion_protection = false

  access_logs {
    bucket  = var.alb_logs_bucket_name
    enabled = true
  }

  tags = {
    Name        = "ALB-Internal-Production"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── 11.2 Target Group ─────────────────────────────────────────
resource "aws_lb_target_group" "his_app" {
  name        = "tg-his-app"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_production_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = {
    Name        = "TG-HIS-App"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── 11.3 Target Group Attachments ─────────────────────────────
resource "aws_lb_target_group_attachment" "app_server_az_a" {
  target_group_arn = aws_lb_target_group.his_app.arn
  target_id        = var.app_server_az_a_id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "app_server_az_b" {
  target_group_arn = aws_lb_target_group.his_app.arn
  target_id        = var.app_server_az_b_id
  port             = 8080
}

# ── 11.4 ALB Listener – HTTPS (443) ───────────────────────────
# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.internal_prod.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
#   certificate_arn   = var.alb_certificate_arn

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.his_app.arn
#   }
# }

# ── 11.5 ALB Listener – HTTP (80 → redirect to HTTPS) ─────────
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.internal_prod.arn
  port              = 80
  protocol          = "HTTP"

  # default_action {
  #   type = "redirect"
  #   redirect {
  #     port        = "443"
  #     protocol    = "HTTPS"
  #     status_code = "HTTP_301"
  #   }
  # }

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.his_app.arn
  }
}
