output "tgw_id" {
  description = "ID of the Transit Gateway"
  value       = aws_ec2_transit_gateway.main.id
}

output "tgw_arn" {
  description = "ARN of the Transit Gateway"
  value       = aws_ec2_transit_gateway.main.arn
}

output "tgw_attachment_production_id" {
  description = "TGW Attachment ID for VPC Production"
  value       = aws_ec2_transit_gateway_vpc_attachment.production.id
}

output "tgw_rt_onpremise_id" {
  description = "ID of TGW Route Table for OnPremise hospitals"
  value       = aws_ec2_transit_gateway_route_table.onpremise.id
}

output "tgw_rt_production_id" {
  description = "ID of TGW Route Table for Production VPC"
  value       = aws_ec2_transit_gateway_route_table.production.id
}
