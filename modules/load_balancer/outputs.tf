output "alb_dns_name" {
  description = "DNS name of the Internal ALB"
  value       = aws_lb.internal_prod.dns_name
}

output "alb_arn" {
  description = "ARN of the Internal ALB"
  value       = aws_lb.internal_prod.arn
}

output "alb_zone_id" {
  description = "Hosted Zone ID of the Internal ALB (for Route53 Alias)"
  value       = aws_lb.internal_prod.zone_id
}

output "target_group_arn" {
  description = "ARN of the HIS App Target Group"
  value       = aws_lb_target_group.his_app.arn
}
