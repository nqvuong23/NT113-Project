###############################################################
# ROOT MAIN.TF – Module Orchestration (v2)
# Architecture: 1 VPC Production, 2 Hospitals on-premise
# Removed: VPC Hub, VPC Shared Services, Hospital 3
# Deployment order follows dependency graph.
###############################################################

# ══════════════════════════════════════════════════════════════
# 1. KMS – Encryption Keys (must come first)
# ══════════════════════════════════════════════════════════════
module "kms" {
  source = "./modules/kms"

  aws_region          = var.aws_region
  project_name        = var.project_name
  environment         = var.environment
  kms_deletion_window = 30
}

# ══════════════════════════════════════════════════════════════
# 2. Storage S3 – Buckets & DynamoDB (CloudTrail needs bucket)
# ══════════════════════════════════════════════════════════════
module "storage_s3" {
  source = "./modules/storage_s3"

  project_name                = var.project_name
  environment                 = var.environment
  medical_data_bucket_name    = "hospital-medical-data-nt113"
  cloudtrail_bucket_name      = "hospital-cloudtrail-logs-nt113"
  alb_logs_bucket_name        = "hospital-alb-logs-nt113"
  terraform_state_bucket_name = "hospital-terraform-state"
  dynamodb_lock_table_name    = "hospital-terraform-lock"
  kms_key_s3_arn              = module.kms.kms_key_s3_arn
  kms_key_general_arn         = module.kms.kms_key_general_arn

  depends_on = [module.kms]
}

# ══════════════════════════════════════════════════════════════
# 3. IAM – Roles & Policies
# ══════════════════════════════════════════════════════════════
module "iam" {
  source = "./modules/iam"

  aws_region             = var.aws_region
  project_name           = var.project_name
  environment            = var.environment
  s3_medical_data_bucket = module.storage_s3.medical_data_bucket_name
  s3_cloudtrail_bucket   = module.storage_s3.cloudtrail_bucket_name
  kms_key_s3_arn         = module.kms.kms_key_s3_arn

  depends_on = [module.storage_s3]
}

# ══════════════════════════════════════════════════════════════
# 4. VPC OnPremise – 2 Hospital Simulated Networks
# ══════════════════════════════════════════════════════════════
module "vpc_onpremise" {
  source = "./modules/vpc_onpremise"

  project_name = var.project_name
  environment  = var.environment
  az_a         = var.az_a

  vpc_cidr_onprem_1 = var.vpc_cidr_onprem_1
  vpc_cidr_onprem_2 = var.vpc_cidr_onprem_2

  public_subnet_cidr_onprem_1 = var.public_subnet_cidr_onprem_1
  public_subnet_cidr_onprem_2 = var.public_subnet_cidr_onprem_2

  workstation_subnet_cidr_onprem_1 = var.workstation_subnet_cidr_onprem_1
  workstation_subnet_cidr_onprem_2 = var.workstation_subnet_cidr_onprem_2

  iot_subnet_cidr_onprem_1 = var.iot_subnet_cidr_onprem_1
  iot_subnet_cidr_onprem_2 = var.iot_subnet_cidr_onprem_2

  wifi_subnet_cidr_onprem_1 = var.wifi_subnet_cidr_onprem_1
  wifi_subnet_cidr_onprem_2 = var.wifi_subnet_cidr_onprem_2

  admin_ip_cidr = var.admin_ip_cidr

}

# ══════════════════════════════════════════════════════════════
# 5. VPC Production – The SINGLE AWS VPC
#    Contains: TGW, ClientVPN, Public, App, DB subnets (×2 AZ)
#    Also: Internet Gateway + 2× NAT Gateway
# ══════════════════════════════════════════════════════════════
module "vpc_production" {
  source = "./modules/vpc_production"

  project_name  = var.project_name
  environment   = var.environment
  cidr_vpc_prod = var.vpc_cidr_prod
  az_a          = var.az_a
  az_b          = var.az_b

  # TGW Attachment Subnets
  subnet_prod_tgw_az_a = var.subnet_prod_tgw_az_a_cidr
  subnet_prod_tgw_az_b = var.subnet_prod_tgw_az_b_cidr

  # Public Subnets (NAT Gateway placement)
  subnet_prod_public_az_a = var.subnet_prod_public_az_a_cidr
  subnet_prod_public_az_b = var.subnet_prod_public_az_b_cidr

  # Client VPN Subnets (min /27 required by AWS)
  subnet_prod_clientvpn_az_a = var.subnet_prod_clientvpn_az_a_cidr
  subnet_prod_clientvpn_az_b = var.subnet_prod_clientvpn_az_b_cidr

  # DB Subnets (RDS – isolated)
  subnet_prod_db_az_a = var.subnet_prod_db_az_a_cidr
  subnet_prod_db_az_b = var.subnet_prod_db_az_b_cidr

  # App Subnets (EC2 HIS, ALB)
  subnet_prod_app_az_a = var.subnet_prod_app_az_a_cidr
  subnet_prod_app_az_b = var.subnet_prod_app_az_b_cidr
}

# ══════════════════════════════════════════════════════════════
# 6. Security Groups & NACLs
# ══════════════════════════════════════════════════════════════
module "security_groups" {
  source = "./modules/security_groups"

  project_name = var.project_name
  environment  = var.environment

  vpc_production_id = module.vpc_production.vpc_id
  onprem_vpc_ids = {
    "1" = module.vpc_onpremise.vpc_ids["1"]
    "2" = module.vpc_onpremise.vpc_ids["2"]
  }

  cidr_vpc_prod = var.vpc_cidr_prod
  cidr_onprem_1 = var.vpc_cidr_onprem_1
  cidr_onprem_2 = var.vpc_cidr_onprem_2

  cidr_client_vpn = var.client_vpn_cidr
  admin_ip_cidr   = var.admin_ip_cidr

  workstation_subnet_onprem_ids = {
    "1" = module.vpc_onpremise.private_subnet_ids["Workstation-1"]
    "2" = module.vpc_onpremise.private_subnet_ids["Workstation-2"]
  }
  iot_subnet_onprem_ids = {
    "1" = module.vpc_onpremise.private_subnet_ids["IOT-1"]
    "2" = module.vpc_onpremise.private_subnet_ids["IOT-2"]
  }
  wifi_subnet_onprem_ids = {
    "1" = module.vpc_onpremise.private_subnet_ids["Wifi-1"]
    "2" = module.vpc_onpremise.private_subnet_ids["Wifi-2"]
  }

  wifi_subnet_onprem_cidrs = {
    "1" = var.wifi_subnet_cidr_onprem_1
    "2" = var.wifi_subnet_cidr_onprem_2
  }
  iot_subnet_onprem_cidrs = {
    "1" = var.iot_subnet_cidr_onprem_1
    "2" = var.iot_subnet_cidr_onprem_2
  }
  workstation_subnet_onprem_cidrs = {
    "1" = var.workstation_subnet_cidr_onprem_1
    "2" = var.workstation_subnet_cidr_onprem_2
  }

  subnet_prod_db_az_a_id = module.vpc_production.subnet_db_az_a_id
  subnet_prod_db_az_b_id = module.vpc_production.subnet_db_az_b_id

  subnet_prod_app_az_a_cidr = var.subnet_prod_app_az_a_cidr
  subnet_prod_app_az_b_cidr = var.subnet_prod_app_az_b_cidr

  depends_on = [module.vpc_production]
}

# ══════════════════════════════════════════════════════════════
# 7. Transit Gateway – Central Router (Production attachment only)
# ══════════════════════════════════════════════════════════════
module "transit_gateway" {
  source = "./modules/transit_gateway"

  project_name                   = var.project_name
  environment                    = var.environment
  tgw_amazon_side_asn            = 64512
  vpc_production_id              = module.vpc_production.vpc_id
  subnet_prod_tgw_az_a_id        = module.vpc_production.subnet_tgw_az_a_id
  subnet_prod_tgw_az_b_id        = module.vpc_production.subnet_tgw_az_b_id
  cidr_onprem_1                  = var.vpc_cidr_onprem_1
  cidr_onprem_2                  = var.vpc_cidr_onprem_2
  cidr_vpc_prod = var.vpc_cidr_prod

  depends_on = [module.vpc_production]
}

# ══════════════════════════════════════════════════════════════
# 8. Compute EC2 – VPN Appliances (OnPremise ×2) first
#    (EIPs needed for Customer Gateways in step 9)
# ══════════════════════════════════════════════════════════════
module "compute_ec2" {
  source = "./modules/compute_ec2"

  project_name = var.project_name
  environment  = var.environment

  key_name               = "hospital-keypair"
  ec2_keypair_public_key = ""

  vpn_ami_ubuntu = var.vpn_ami_ubuntu
  app_ami_al2023 = var.app_ami_al2023

  vpn_appliance_instance_type = "t3.micro"
  app_server_instance_type    = "t3.small"
  bastion_instance_type       = "t3.micro"
  workstation_instance_type   = "t3.micro"

  onprem_public_subnet_ids  = module.vpc_onpremise.public_subnet_ids
  onprem_private_subnet_ids = module.vpc_onpremise.private_subnet_ids

  # Both outputs are now maps (key: 1/2) – matches map(string) variables
  onprem_sg_vpn_appliance_ids = module.security_groups.sg_vpn_appliance_ids
  sg_onprem_workstation_ids   = module.security_groups.sg_workstation_ids
  sg_app_server_id            = module.security_groups.sg_app_server_id
  sg_bastion_id               = module.security_groups.sg_bastion_id

  onprem_eip_allocation_ids      = module.vpc_onpremise.eip_allocation_ids
  vpn_appliance_instance_profile = module.iam.vpn_appliance_instance_profile_name
  app_server_instance_profile    = module.iam.app_server_instance_profile_name
  bastion_instance_profile       = module.iam.bastion_instance_profile_name
  subnet_prod_app_az_a_id        = module.vpc_production.subnet_app_az_a_id
  subnet_prod_app_az_b_id        = module.vpc_production.subnet_app_az_b_id
  subnet_prod_public_az_a_id     = module.vpc_production.subnet_public_az_a_id
  kms_key_general_arn            = module.kms.kms_key_general_arn

  depends_on = [module.vpc_onpremise, module.security_groups, module.iam]
}

# ══════════════════════════════════════════════════════════════
# 9. VPN Site-to-Site – 2 Hospital VPN Connections
# ══════════════════════════════════════════════════════════════
module "vpn_site_to_site" {
  source = "./modules/vpn_site_to_site"

  project_name = var.project_name
  environment  = var.environment

  tgw_id               = module.transit_gateway.tgw_id
  tgw_rt_onpremise_id  = module.transit_gateway.tgw_rt_onpremise_id
  tgw_rt_production_id = module.transit_gateway.tgw_rt_production_id

  onprem_eip_public_ips = module.vpc_onpremise.eip_public_ips

  cgw_bgp_asn_1 = 65001
  cgw_bgp_asn_2 = 65002
  cidr_onprem_1 = var.vpc_cidr_onprem_1
  cidr_onprem_2 = var.vpc_cidr_onprem_2

  depends_on = [module.transit_gateway, module.compute_ec2]
}

# ══════════════════════════════════════════════════════════════
# 10. Route Tables – Full Routing (Production VPC)
# ══════════════════════════════════════════════════════════════
module "route_tables" {
  source = "./modules/route_tables"

  project_name = var.project_name
  environment  = var.environment

  tgw_id = module.transit_gateway.tgw_id

  vpc_production_id   = module.vpc_production.vpc_id
  vpc_production_cidr = var.vpc_cidr_prod

  igw_prod_id = module.vpc_production.igw_id

  nat_gateway_prod_az_a_id = module.vpc_production.nat_gateway_az_a_id
  nat_gateway_prod_az_b_id = module.vpc_production.nat_gateway_az_b_id

  subnet_prod_public_az_a_id = module.vpc_production.subnet_public_az_a_id
  subnet_prod_public_az_b_id = module.vpc_production.subnet_public_az_b_id

  subnet_prod_tgw_az_a_id = module.vpc_production.subnet_tgw_az_a_id
  subnet_prod_tgw_az_b_id = module.vpc_production.subnet_tgw_az_b_id

  subnet_prod_clientvpn_az_a_id = module.vpc_production.subnet_clientvpn_az_a_id
  subnet_prod_clientvpn_az_b_id = module.vpc_production.subnet_clientvpn_az_b_id

  subnet_prod_app_az_a_id = module.vpc_production.subnet_app_az_a_id
  subnet_prod_app_az_b_id = module.vpc_production.subnet_app_az_b_id

  subnet_prod_db_az_a_id = module.vpc_production.subnet_db_az_a_id
  subnet_prod_db_az_b_id = module.vpc_production.subnet_db_az_b_id

  cidr_onprem_1 = var.vpc_cidr_onprem_1
  cidr_onprem_2 = var.vpc_cidr_onprem_2

  # All onprem collections are now maps (key: "1"/"2") for consistency
  onprem_vpc_ids = module.vpc_onpremise.vpc_ids

  onprem_public_subnet_ids = module.vpc_onpremise.public_subnet_ids

  vpn_appliance_primary_eni_ids = module.compute_ec2.vpn_appliance_primary_network_interface_ids

  onprem_private_subnet_ids = {
    "1" = module.vpc_onpremise.private_subnet_ids["Workstation-1"]
    "2" = module.vpc_onpremise.private_subnet_ids["Workstation-2"]
  }

  igw_onprem_ids       = module.vpc_onpremise.igw_onprem_ids
  nat_gateway_onprem_1 = module.vpc_onpremise.nat_gateway_onprem_1

  depends_on = [module.transit_gateway, module.vpc_production]
}

# ══════════════════════════════════════════════════════════════
# 11. Client VPN – Remote Doctor Access (in Production VPC)
# ══════════════════════════════════════════════════════════════
module "vpn_client" {
  source = "./modules/vpn_client"

  project_name                  = var.project_name
  environment                   = var.environment
  vpc_production_id             = module.vpc_production.vpc_id
  subnet_prod_clientvpn_az_a_id = module.vpc_production.subnet_clientvpn_az_a_id
  subnet_prod_clientvpn_az_b_id = module.vpc_production.subnet_clientvpn_az_b_id
  subnet_prod_app_az_a_cidr     = var.subnet_prod_app_az_a_cidr
  subnet_prod_app_az_b_cidr     = var.subnet_prod_app_az_b_cidr
  cidr_client_vpn               = var.client_vpn_cidr
  sg_client_vpn_id              = module.security_groups.sg_client_vpn_id
  kms_key_general_arn           = module.kms.kms_key_general_arn
  vpn_log_retention_days        = 90
  vpn_domain                    = "hospital.internal"

  depends_on = [module.vpc_production, module.security_groups]
}

# ══════════════════════════════════════════════════════════════
# 12. Database RDS – Hospital Patient Records
# ══════════════════════════════════════════════════════════════
module "database_rds" {
  source = "./modules/database_rds"

  project_name              = var.project_name
  environment               = var.environment
  db_engine                 = "mysql"
  db_engine_version         = "8.4.8"
  db_instance_class         = "db.t3.micro"
  db_parameter_group_family = "mysql8.4"
  db_allocated_storage      = 100
  db_max_allocated_storage  = 500
  db_name                   = "hospital_emr"
  db_username               = "dbadmin"
  db_password               = var.db_password
  db_backup_retention_days  = 7
  db_subnet_group_name      = module.vpc_production.db_subnet_group_name
  sg_rds_id                 = module.security_groups.sg_rds_id
  kms_key_rds_arn           = module.kms.kms_key_rds_arn

  depends_on = [module.vpc_production, module.security_groups, module.kms]
}

# ══════════════════════════════════════════════════════════════
# 13. Load Balancer – Internal ALB for HIS
# ══════════════════════════════════════════════════════════════
module "load_balancer" {
  source = "./modules/load_balancer"

  project_name            = var.project_name
  environment             = var.environment
  vpc_production_id       = module.vpc_production.vpc_id
  subnet_prod_app_az_a_id = module.vpc_production.subnet_app_az_a_id
  subnet_prod_app_az_b_id = module.vpc_production.subnet_app_az_b_id
  sg_alb_internal_id      = module.security_groups.sg_alb_internal_id
  app_server_az_a_id      = module.compute_ec2.app_server_az_a_id
  app_server_az_b_id      = module.compute_ec2.app_server_az_b_id
  alb_logs_bucket_name    = module.storage_s3.alb_logs_bucket_name
  alb_certificate_arn     = var.alb_certificate_arn

  depends_on = [module.compute_ec2, module.storage_s3]
}

# ══════════════════════════════════════════════════════════════
# 14. VPC Endpoints – AWS PrivateLink
# ══════════════════════════════════════════════════════════════
module "vpc_endpoints" {
  source = "./modules/vpc_endpoints"

  project_name            = var.project_name
  environment             = var.environment
  aws_region              = var.aws_region
  vpc_production_id       = module.vpc_production.vpc_id
  subnet_prod_app_az_a_id = module.vpc_production.subnet_app_az_a_id
  subnet_prod_app_az_b_id = module.vpc_production.subnet_app_az_b_id
  sg_vpc_endpoints_id     = module.security_groups.sg_vpc_endpoints_id
  rt_prod_app_az_a_id     = module.route_tables.rt_prod_app_az_a_id
  rt_prod_app_az_b_id     = module.route_tables.rt_prod_app_az_b_id

  depends_on = [module.route_tables, module.security_groups]
}

# ══════════════════════════════════════════════════════════════
# 15. DNS Route 53 – Private Hosted Zone (Production only)
# ══════════════════════════════════════════════════════════════
module "dns_route53" {
  source = "./modules/dns_route53"

  project_name      = var.project_name
  environment       = var.environment
  aws_region        = var.aws_region
  private_zone_name = "hospital.internal"
  vpc_production_id = module.vpc_production.vpc_id
  alb_dns_name      = module.load_balancer.alb_dns_name
  alb_zone_id       = module.load_balancer.alb_zone_id
  rds_address       = module.database_rds.rds_address

  depends_on = [module.load_balancer, module.database_rds]
}

# ══════════════════════════════════════════════════════════════
# 16. Monitoring – CloudWatch, CloudTrail, Flow Logs, SNS
# ══════════════════════════════════════════════════════════════
module "monitoring" {
  source = "./modules/monitoring"

  project_name                  = var.project_name
  environment                   = var.environment
  aws_region                    = var.aws_region
  admin_email                   = var.admin_email
  kms_key_general_arn           = module.kms.kms_key_general_arn
  kms_key_s3_arn                = module.kms.kms_key_s3_arn
  cloudtrail_bucket_name        = module.storage_s3.cloudtrail_bucket_name
  cloudtrail_role_arn           = module.iam.cloudtrail_role_arn
  flowlogs_retention_days       = 90
  cloudtrail_log_retention_days = 365
  appserver_log_retention_days  = 30
  vpc_production_id             = module.vpc_production.vpc_id
  vpc_flowlogs_role_arn         = module.iam.vpc_flowlogs_role_arn
  vpn_connection_id_1           = module.vpn_site_to_site.vpn_connection_ids["1"]
  vpn_connection_id_2           = module.vpn_site_to_site.vpn_connection_ids["2"]
  rds_identifier                = module.database_rds.rds_identifier
  alb_arn_suffix                = module.load_balancer.alb_arn
  tg_arn_suffix                 = module.load_balancer.target_group_arn
  app_server_az_a_id            = module.compute_ec2.app_server_az_a_id
  app_server_az_b_id            = module.compute_ec2.app_server_az_b_id
  route53_health_check_id       = module.dns_route53.health_check_id

  depends_on = [
    module.storage_s3,
    module.iam,
    module.vpc_production,
    module.vpn_site_to_site,
    module.database_rds,
    module.load_balancer,
    module.dns_route53
  ]
}
