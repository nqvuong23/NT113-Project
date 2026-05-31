output "sns_topic_arn" {
  description = "ARN of the Hospital Alerts SNS Topic"
  value       = aws_sns_topic.hospital_alerts.arn
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail"
  value       = aws_cloudtrail.hospital_audit.arn
}

output "cw_log_group_flowlogs_prod_arn" {
  description = "ARN of the VPC Flow Logs CloudWatch log group (Production)"
  value       = aws_cloudwatch_log_group.vpc_flowlogs_production.arn
}

output "cw_log_group_cloudtrail_arn" {
  description = "ARN of the CloudTrail CloudWatch log group"
  value       = aws_cloudwatch_log_group.cloudtrail.arn
}
