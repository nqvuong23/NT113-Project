# ===========================================================
# ROOT TERRAFORM VARIABLE VALUES – v2
# 1 VPC Production, 2 Hospitals on-premise
# ===========================================================

aws_region   = "ap-southeast-1"
project_name = "hospital-aws"
environment  = "dev"

# Availability Zones
az_a = "ap-southeast-1a"
az_b = "ap-southeast-1b"

# VPC Production CIDR (single AWS VPC)
vpc_cidr_prod = "10.0.4.0/22"

subnet_prod_tgw_az_a_cidr = "10.0.4.0/28"
subnet_prod_tgw_az_b_cidr = "10.0.5.0/28"

subnet_prod_public_az_a_cidr = "10.0.4.16/28"
subnet_prod_public_az_b_cidr = "10.0.5.16/28"

subnet_prod_clientvpn_az_a_cidr = "10.0.4.32/27"
subnet_prod_clientvpn_az_b_cidr = "10.0.5.32/27"

subnet_prod_db_az_a_cidr = "10.0.4.64/26"
subnet_prod_db_az_b_cidr = "10.0.5.64/26"

subnet_prod_app_az_a_cidr = "10.0.4.128/25"
subnet_prod_app_az_b_cidr = "10.0.5.128/25"

# OnPremise Hospital CIDRs (2 hospitals)
vpc_cidr_onprem_1 = "192.168.10.0/24"

public_subnet_cidr_onprem_1      = "192.168.10.0/26"
workstation_subnet_cidr_onprem_1 = "192.168.10.64/26"
iot_subnet_cidr_onprem_1         = "192.168.10.128/26"
wifi_subnet_cidr_onprem_1        = "192.168.10.192/26"

vpc_cidr_onprem_2 = "192.168.20.0/24"

public_subnet_cidr_onprem_2      = "192.168.20.0/26"
workstation_subnet_cidr_onprem_2 = "192.168.20.64/26"
iot_subnet_cidr_onprem_2         = "192.168.20.128/26"
wifi_subnet_cidr_onprem_2        = "192.168.20.192/26"

# Client VPN CIDR (doctors remote access will use in Production VPC)
client_vpn_cidr = "10.0.200.0/22"

# Admin / Notification
admin_email   = "nguyenquocvuong160705@gmail.com"
admin_ip_cidr = "0.0.0.0/0" # Replace with actual admin IP, e.g. "203.0.113.10/32"

# AMI IDs (ap-southeast-1 – update as needed)
# Ubuntu 22.04 LTS: ami-0df7a207adb9748c7 (example, check AWS Console)
vpn_ami_ubuntu = "ami-0a56f8447277affd8"
# Amazon Linux 2023: ami-0c1c30571d2dae5c9 (example, check AWS Console)
app_ami_al2023 = "ami-0543dbdaf4e114be7"

# RDS Master Password (use Secrets Manager in production)
db_password = "Vuongnguyen1607"

# ALB Certificate ARN (must be pre-created in ACM for internal domain)
# Replace with actual ACM cert ARN for hospital.internal
alb_certificate_arn = "arn:aws:acm:ap-southeast-1:123456789012:certificate/replace-with-real-cert-id"