output "app_server_instance_profile_name" {
  description = "EC2 instance profile name for App Server"
  value       = aws_iam_instance_profile.ec2_app_server.name
}

output "app_server_role_arn" {
  description = "ARN of the App Server IAM role"
  value       = aws_iam_role.ec2_app_server.arn
}

output "vpn_appliance_instance_profile_name" {
  description = "EC2 instance profile name for VPN Appliance"
  value       = aws_iam_instance_profile.ec2_vpn_appliance.name
}

output "bastion_instance_profile_name" {
  description = "EC2 instance profile name for Bastion"
  value       = aws_iam_instance_profile.ec2_bastion.name
}

output "cloudtrail_role_arn" {
  description = "ARN of CloudTrail IAM role"
  value       = aws_iam_role.cloudtrail_s3.arn
}

output "vpc_flowlogs_role_arn" {
  description = "ARN of VPC Flow Logs IAM role"
  value       = aws_iam_role.vpc_flowlogs_cw.arn
}
