output "rt_prod_public_id" {
  description = "Route Table ID for Production Public subnets (→ IGW)"
  value       = aws_route_table.prod_public.id
}

output "rt_prod_tgw_id" {
  description = "Route Table ID for Production TGW subnets (local only)"
  value       = aws_route_table.prod_tgw.id
}

output "rt_prod_clientvpn_id" {
  description = "Route Table ID for Production Client VPN subnets (local only)"
  value       = aws_route_table.prod_clientvpn.id
}

output "rt_prod_app_az_a_id" {
  description = "Route Table ID for Production App subnet AZ-A (→ NAT GW AZ-A)"
  value       = aws_route_table.prod_app_az_a.id
}

output "rt_prod_app_az_b_id" {
  description = "Route Table ID for Production App subnet AZ-B (→ NAT GW AZ-B)"
  value       = aws_route_table.prod_app_az_b.id
}

output "rt_prod_db_id" {
  description = "Route Table ID for Production DB subnets (isolated)"
  value       = aws_route_table.prod_db.id
}
