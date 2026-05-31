output "vpc_ids" {
  description = "Map of VPC IDs for each hospital (key: 1/2)"
  value = {for k,v in aws_vpc.onpremise : k => v.id}
}

output "public_subnet_ids" {
  description = "Map of public subnet IDs (key: 1/2)"
  value = {for k,v in aws_subnet.onpremise_public : k => v.id}
}

output "private_subnet_ids" {
  description = "Map of private subnet IDs (key: 1/2)"
  value = {
    for k, v in aws_subnet.onpremise_private : k => v.id
  }
}

output "eip_allocation_ids" {
  description = "Map of EIP allocation IDs for VPN Appliances (key: 1/2)"
  value = {
    for k, v in aws_eip.vpn_appliance : k => v.allocation_id
  }
}

output "eip_public_ips" {
  description = "Map of EIP public IP addresses for VPN Appliances (key: 1/2)"
  value = {
    for k, v in aws_eip.vpn_appliance : k => v.public_ip
  }
}

output "nat_gateway_onprem_1" {
  value = aws_nat_gateway.nat_on_premise_1.id
}

output "igw_onprem_ids" {
  value = {for k,v in aws_internet_gateway.onpremise : k => v.id}
}
