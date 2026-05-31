output "vpc_id" {
  description = "ID of VPC Production"
  value       = aws_vpc.production.id
}

output "igw_id" {
  description = "ID of Internet Gateway for VPC Production"
  value       = aws_internet_gateway.prod.id
}

output "nat_gateway_az_a_id" {
  description = "ID of NAT Gateway in AZ-A"
  value       = aws_nat_gateway.prod_az_a.id
}

output "nat_gateway_az_b_id" {
  description = "ID of NAT Gateway in AZ-B"
  value       = aws_nat_gateway.prod_az_b.id
}

# TGW subnets
output "subnet_tgw_az_a_id" {
  description = "ID of TGW Attachment Subnet AZ-A"
  value       = aws_subnet.prod_tgw_az_a.id
}

output "subnet_tgw_az_b_id" {
  description = "ID of TGW Attachment Subnet AZ-B"
  value       = aws_subnet.prod_tgw_az_b.id
}

# Client VPN subnets
output "subnet_clientvpn_az_a_id" {
  description = "ID of Client VPN Subnet AZ-A"
  value       = aws_subnet.prod_clientvpn_az_a.id
}

output "subnet_clientvpn_az_b_id" {
  description = "ID of Client VPN Subnet AZ-B"
  value       = aws_subnet.prod_clientvpn_az_b.id
}

# Public subnets (NAT GW placement)
output "subnet_public_az_a_id" {
  description = "ID of Public Subnet AZ-A (NAT GW)"
  value       = aws_subnet.prod_public_az_a.id
}

output "subnet_public_az_b_id" {
  description = "ID of Public Subnet AZ-B (NAT GW)"
  value       = aws_subnet.prod_public_az_b.id
}

# App subnets
output "subnet_app_az_a_id" {
  description = "ID of App Subnet AZ-A"
  value       = aws_subnet.prod_app_az_a.id
}

output "subnet_app_az_b_id" {
  description = "ID of App Subnet AZ-B"
  value       = aws_subnet.prod_app_az_b.id
}

# DB subnets
output "subnet_db_az_a_id" {
  description = "ID of DB Subnet AZ-A"
  value       = aws_subnet.prod_db_az_a.id
}

output "subnet_db_az_b_id" {
  description = "ID of DB Subnet AZ-B"
  value       = aws_subnet.prod_db_az_b.id
}

# DB subnet group
output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.prod.name
}
