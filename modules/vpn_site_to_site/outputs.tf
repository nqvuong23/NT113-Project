output "vpn_connection_ids" {
  description = "Map of VPN Connection IDs (key: 1/2/3)"
  value = {
    for k, v in aws_vpn_connection.hospital : k => v.id
  }
}

output "vpn_tunnel1_addresses" {
  description = "Map of VPN Tunnel 1 outside IP addresses (configure StrongSwan)"
  value = {
    for k, v in aws_vpn_connection.hospital : k => v.tunnel1_address
  }
  sensitive = false
}

output "vpn_tunnel1_preshared_keys" {
  description = "Map of VPN Tunnel 1 pre-shared keys (configure StrongSwan)"
  value = {
    for k, v in aws_vpn_connection.hospital : k => v.tunnel1_preshared_key
  }
  sensitive = true
}

output "vpn_tunnel2_addresses" {
  description = "Map of VPN Tunnel 2 outside IP addresses (HA backup)"
  value = {
    for k, v in aws_vpn_connection.hospital : k => v.tunnel2_address
  }
  sensitive = false
}

output "vpn_tunnel2_preshared_keys" {
  description = "Map of VPN Tunnel 2 pre-shared keys (HA backup)"
  value = {
    for k, v in aws_vpn_connection.hospital : k => v.tunnel2_preshared_key
  }
  sensitive = true
}

output "tgw_vpn_attachment_ids" {
  description = "Map of TGW VPN attachment IDs (key: 1/2/3)"
  value = {
    for k, v in aws_vpn_connection.hospital : k => v.transit_gateway_attachment_id
  }
}
