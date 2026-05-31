output "sg_client_vpn_id" {
  description = "Security Group ID for Client VPN Endpoint"
  value       = aws_security_group.client_vpn_endpoint.id
}

output "sg_alb_internal_id" {
  description = "Security Group ID for Internal ALB"
  value       = aws_security_group.alb_internal.id
}

output "sg_app_server_id" {
  description = "Security Group ID for App Server"
  value       = aws_security_group.app_server.id
}

output "sg_rds_id" {
  description = "Security Group ID for RDS"
  value       = aws_security_group.rds.id
}

output "sg_bastion_id" {
  description = "Security Group ID for Bastion Host"
  value       = aws_security_group.bastion.id
}

output "sg_vpc_endpoints_id" {
  description = "Security Group ID for VPC Endpoints"
  value       = aws_security_group.vpc_endpoints.id
}

output "sg_workstation_ids" {
  description = "Map of Workstation Security Group IDs per hospital (key: 1/2)"
  value       = { for k, v in aws_security_group.workstation : k => v.id }
}

output "sg_vpn_appliance_ids" {
  description = "Map of VPN Appliance Security Group IDs per hospital (key: 1/2)"
  value       = { for k, v in aws_security_group.vpn_appliance : k => v.id }
}
