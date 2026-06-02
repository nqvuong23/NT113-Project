###############################################################
# MODULE 08 – COMPUTE EC2
# EC2 instances: VPN Appliances (×2 on-premise), App Servers (×2 AZ),
# Bastion Host (Production Public Subnet), Workstations (×2), Key Pair
###############################################################

# ── 8.1 EC2 VPN Appliances (OnPremise – ×2) ──────────────────
resource "aws_instance" "vpn_appliance" {
  for_each = {
    "1" = {
      subnet_id = var.onprem_public_subnet_ids["1"]
      sg_id     = var.onprem_sg_vpn_appliance_ids["1"]
    }
    "2" = {
      subnet_id = var.onprem_public_subnet_ids["2"]
      sg_id     = var.onprem_sg_vpn_appliance_ids["2"]
    }
  }

  ami                    = var.vpn_ami_ubuntu
  instance_type          = var.vpn_appliance_instance_type
  subnet_id              = each.value.subnet_id
  vpc_security_group_ids = [each.value.sg_id]
  source_dest_check      = false # Required – EC2 acts as VPN router
  iam_instance_profile   = var.vpn_appliance_instance_profile

  tags = {
    Name        = "EC2-VPN-Appliance-Hospital-${each.key}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── 8.2 EIP Association for VPN Appliances ────────────────────
resource "aws_eip_association" "vpn_appliance" {
  for_each = aws_instance.vpn_appliance

  instance_id   = each.value.id
  allocation_id = var.onprem_eip_allocation_ids[each.key]
}

# ── 8.3 EC2 App Servers (VPC Production – 2 AZ) ──────────────
# Merged from two separate resources into a single for_each
resource "aws_instance" "app_server" {
  for_each = {
    "az_a" = {
      subnet_id = var.subnet_prod_app_az_a_id
      name      = "EC2-AppServer-HIS-AZ-A"
    }
    "az_b" = {
      subnet_id = var.subnet_prod_app_az_b_id
      name      = "EC2-AppServer-HIS-AZ-B"
    }
  }

  ami                    = var.app_ami_al2023
  instance_type          = var.app_server_instance_type
  subnet_id              = each.value.subnet_id
  vpc_security_group_ids = [var.sg_app_server_id]
  iam_instance_profile   = var.app_server_instance_profile

  root_block_device {
    encrypted   = true
    kms_key_id  = var.kms_key_general_arn
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name        = each.value.name
    Environment = var.environment
    Project     = var.project_name
  }
}

# ── 8.4 EC2 Bastion Host (Production Public Subnet) ──────────
# Note: Consider replacing with SSM Session Manager to avoid opening port 22.
# resource "aws_instance" "bastion" {
#   ami                         = var.app_ami_al2023
#   instance_type               = var.bastion_instance_type
#   subnet_id                   = var.subnet_prod_public_az_a_id
#   vpc_security_group_ids      = [var.sg_bastion_id]
#   associate_public_ip_address = true
#   iam_instance_profile        = var.bastion_instance_profile

#   root_block_device {
#     encrypted   = true
#     kms_key_id  = var.kms_key_general_arn
#     volume_size = 20
#     volume_type = "gp3"
#   }

#   tags = {
#     Name        = "EC2-Bastion-Production"
#     Environment = var.environment
#     Project     = var.project_name
#   }
# }

# ── 8.5 EC2 Workstations (OnPremise Private Subnets – ×2) ────
resource "aws_instance" "workstation" {
  for_each = {
    "1" = {
      subnet_id = var.onprem_private_subnet_ids["Workstation-1"]
      sg_id     = var.sg_onprem_workstation_ids["1"]
    }
    "2" = {
      subnet_id = var.onprem_private_subnet_ids["Workstation-2"]
      sg_id     = var.sg_onprem_workstation_ids["2"]
    }
  }

  ami                    = var.app_ami_al2023
  instance_type          = var.workstation_instance_type
  subnet_id              = each.value.subnet_id
  vpc_security_group_ids = [each.value.sg_id]
  iam_instance_profile   = var.vpn_appliance_instance_profile

  tags = {
    Name        = "EC2-Workstation-Hospital-${each.key}"
    Environment = var.environment
    Project     = var.project_name
  }
}
