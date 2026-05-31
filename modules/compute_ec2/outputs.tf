output "vpn_appliance_instance_ids" {
  description = "Map of VPN Appliance EC2 instance IDs (key: 1/2)"
  value = {
    for k, v in aws_instance.vpn_appliance : k => v.id
  }
}

output "vpn_appliance_primary_network_interface_ids" {
  description = "Map of VPN Appliance primary ENI IDs (key: 1/2)"
  value = {
    for k, v in aws_instance.vpn_appliance : k => v.primary_network_interface_id
  }
}

output "app_server_az_a_id" {
  description = "EC2 Instance ID of App Server AZ-A"
  value       = aws_instance.app_server["az_a"].id
}

output "app_server_az_b_id" {
  description = "EC2 Instance ID of App Server AZ-B"
  value       = aws_instance.app_server["az_b"].id
}

# output "bastion_public_ip" {
#   description = "Public IP of Bastion Host (Production Public Subnet)"
#   value       = aws_instance.bastion.public_ip
# }
