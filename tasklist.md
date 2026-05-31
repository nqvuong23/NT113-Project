# TERRAFORM TASK LIST – HẠ TẦNG MẠNG AWS CHO HỆ THỐNG 2 BỆNH VIỆN ĐA KHOA (v2)

> **Mục tiêu:** Triển khai toàn bộ hạ tầng mạng AWS bằng Terraform theo kiến trúc đơn giản hóa: **1 VPC Production duy nhất** trên AWS kết nối với 2 bệnh viện on-premise (giả lập) qua Site-to-Site VPN + Transit Gateway, và hỗ trợ bác sĩ từ xa qua AWS Client VPN.

> **Thay đổi so với v1:**
> - Giảm từ 3 xuống **2 bệnh viện** on-premise
> - Loại bỏ VPC Hub và VPC Shared Services → gộp toàn bộ vào **1 VPC Production** duy nhất
> - VPC Production đảm nhận: nhận kết nối TGW, nhận Client VPN, chạy app, chạy DB, NAT Gateway

---

## MỤC LỤC MODULE

| STT | Module | Mô tả |
|-----|--------|-------|
| 00 | `root / provider` | Provider AWS, backend S3, biến toàn cục |
| 01 | `module/vpc_onpremise` | 2 VPC giả lập bệnh viện on-premise |
| 02 | `module/vpc_production` | 1 VPC Production duy nhất – toàn bộ hạ tầng AWS |
| 03 | `module/transit_gateway` | AWS Transit Gateway & attachments |
| 04 | `module/vpn_site_to_site` | Site-to-Site VPN – 2 bệnh viện |
| 05 | `module/vpn_client` | AWS Client VPN – bác sĩ từ xa |
| 06 | `module/route_tables` | Route Tables toàn bộ hệ thống |
| 07 | `module/security_groups` | Security Groups & NACLs |
| 08 | `module/compute_ec2` | EC2 – VPN Appliance (OnPremise), App Server, Bastion |
| 09 | `module/load_balancer` | Internal Application Load Balancer |
| 10 | `module/database_rds` | Amazon RDS – cơ sở dữ liệu bệnh nhân |
| 11 | `module/storage_s3` | Amazon S3 – lưu trữ, logs, backup |
| 12 | `module/kms` | AWS KMS – quản lý khóa mã hóa |
| 13 | `module/iam` | IAM Roles & Policies |
| 14 | `module/vpc_endpoints` | VPC Endpoints (PrivateLink) |
| 15 | `module/dns_route53` | Amazon Route 53 – Private Hosted Zone |
| 16 | `module/monitoring` | CloudWatch, CloudTrail, VPC Flow Logs, SNS |

---

## MODULE 00 – ROOT / PROVIDER & BACKEND

### Mục tiêu
Khởi tạo provider AWS, cấu hình Terraform backend trên S3, khai báo biến và output toàn cục.

### Files cần tạo
```
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
└── backend.tf
```

### `backend.tf` – Terraform State Backend
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `terraform { backend "s3" }` | `bucket` | `"hospital-terraform-state-<account_id>"` |
| | `key` | `"hospital/terraform.tfstate"` |
| | `region` | `"ap-southeast-1"` |
| | `encrypt` | `true` |
| | `dynamodb_table` | `"hospital-terraform-lock"` |

> **Lưu ý:** Tạo S3 bucket và DynamoDB table bằng tay (hoặc `bootstrap` script) trước khi `terraform init`.

### `variables.tf` – Biến toàn cục
| Biến | Giá trị mặc định | Mô tả |
|------|-----------------|-------|
| `aws_region` | `"ap-southeast-1"` | Region triển khai |
| `project_name` | `"hospital-aws"` | Tiền tố tên resource |
| `environment` | `"dev"` | Môi trường |
| `az_a` | `"ap-southeast-1a"` | AZ thứ nhất |
| `az_b` | `"ap-southeast-1b"` | AZ thứ hai |
| `cidr_vpc_prod` | `"10.0.4.0/22"` | CIDR VPC Production (duy nhất) |
| `cidr_onprem_1` | `"192.168.10.0/24"` | CIDR Bệnh viện 1 |
| `cidr_onprem_2` | `"192.168.20.0/24"` | CIDR Bệnh viện 2 |
| `cidr_client_vpn` | `"10.0.200.0/22"` | CIDR dải IP cấp cho Client VPN *(AWS yêu cầu ≥ /22)* |
| `admin_email` | `"it-team@hospital.local"` | Email nhận cảnh báo SNS |

---

## MODULE 01 – VPC ONPREMISE (Giả lập 2 Bệnh viện)

### Mục tiêu
Tạo 2 VPC độc lập đóng vai trò mạng nội bộ của 2 bệnh viện. Mỗi VPC chứa 1 EC2 Linux cài **StrongSwan** làm VPN Appliance (Customer Gateway) và 1 EC2 giả lập Workstation nhân viên.

### Lặp lại cho: `hospital-1`, `hospital-2`

#### 1.1 – VPC OnPremise
| Resource | Tham số | Giá trị BV-1 / BV-2 |
|----------|---------|----------------------|
| `aws_vpc` | `cidr_block` | `192.168.10.0/24` / `192.168.20.0/24` |
| | `enable_dns_support` | `true` |
| | `enable_dns_hostnames` | `true` |
| | `tags.Name` | `VPC-OnPremise-1` / `VPC-OnPremise-2` |

#### 1.2 – Internet Gateway
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_internet_gateway` | `vpc_id` | ID VPC OnPremise tương ứng |
| | `tags.Name` | `IGW-OnPremise-1` / `IGW-OnPremise-2` |

#### 1.3 – Public Subnet (chứa EC2 VPN Appliance)
| Resource | Tham số | Giá trị BV-1 / BV-2 |
|----------|---------|----------------------|
| `aws_subnet` | `cidr_block` | `192.168.10.0/25` / `192.168.20.0/25` |
| | `availability_zone` | `var.az_a` |
| | `map_public_ip_on_launch` | `true` |
| | `tags.Name` | `Subnet-OnPremise-Public-1` / `Subnet-OnPremise-Public-2` |

#### 1.4 – Private Subnet (chứa EC2 Workstation giả lập)
| Resource | Tham số | Giá trị BV-1 / BV-2 |
|----------|---------|----------------------|
| `aws_subnet` | `cidr_block` | `192.168.10.128/25` / `192.168.20.128/25` |
| | `availability_zone` | `var.az_a` |
| | `map_public_ip_on_launch` | `false` |
| | `tags.Name` | `Subnet-OnPremise-Private-1` / `Subnet-OnPremise-Private-2` |

#### 1.5 – Route Table: Public Subnet
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_route_table` | `vpc_id` | ID VPC OnPremise |
| | Route `0.0.0.0/0` → | Internet Gateway |
| `aws_route_table_association` | `subnet_id` | Public Subnet |

#### 1.6 – Route Table: Private Subnet (Workstation → AWS qua VPN Appliance)
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_route_table` | `vpc_id` | ID VPC OnPremise |
| | Route `10.0.4.0/22` → | ENI của EC2 VPN Appliance (`network_interface_id`) |
| `aws_route_table_association` | `subnet_id` | Private Subnet |

> **Lưu ý:** Route này trỏ traffic đến dải AWS vào ENI của EC2 VPN Appliance để StrongSwan xử lý. Yêu cầu `source_dest_check = false` trên EC2 (xem Module 08).

#### 1.7 – Elastic IP cho VPN Appliance
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_eip` (x2) | `domain` | `"vpc"` |
| | `tags.Name` | `EIP-OnPremise-VPN-1` / `EIP-OnPremise-VPN-2` |

#### 1.8 – Security Group cho VPN Appliance EC2
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_security_group` | `name` | `sg-onpremise-vpn-appliance-1` / `-2` |
| | `vpc_id` | ID VPC OnPremise tương ứng |
| Inbound UDP 500 | Source | `0.0.0.0/0` (IKE – thương lượng SA) |
| Inbound UDP 4500 | Source | `0.0.0.0/0` (NAT-Traversal) |
| Inbound Protocol ESP (50) | Source | `0.0.0.0/0` (dữ liệu mã hóa IPsec) |
| Inbound SSH 22 | Source | IP quản trị cụ thể (hoặc dùng SSM) |
| Inbound All | Source | CIDR của Private Subnet nội bộ (cho Workstation → VPN Appliance) |
| Outbound All | Destination | `0.0.0.0/0` |

---

## MODULE 02 – VPC PRODUCTION (10.0.4.0/22) – VPC DUY NHẤT TRÊN AWS

### Mục tiêu
Tạo 1 VPC Production duy nhất chứa toàn bộ hạ tầng AWS. VPC này có **5 loại subnet × 2 AZ = 10 subnets**, đảm nhận đồng thời: tiếp nhận kết nối từ Transit Gateway (on-premise), tiếp nhận kết nối từ Client VPN (bác sĩ), chạy ứng dụng HIS, lưu trữ DB, và cung cấp đường ra Internet một chiều qua NAT Gateway.

### Sơ đồ phân tầng Subnet

```
VPC Production (10.0.4.0/22)
┌──────────────────────────────────────────────────────────────────┐
│              AZ-A (ap-southeast-1a)                              │
│  Subnet-Prod-TGW-AZ-A        10.0.4.0/28   (16 IPs)  – TGW ENI │
│  Subnet-Prod-ClientVPN-AZ-A  10.0.4.16/27  (32 IPs)  – VPN ENI │
│  Subnet-Prod-Public-AZ-A     10.0.4.48/28  (16 IPs)  – NAT GW  │
│  Subnet-Prod-App-AZ-A        10.0.4.64/25  (128 IPs) – EC2 HIS │
│  Subnet-Prod-DB-AZ-A         10.0.5.0/26   (64 IPs)  – RDS     │
├──────────────────────────────────────────────────────────────────┤
│              AZ-B (ap-southeast-1b)                              │
│  Subnet-Prod-TGW-AZ-B        10.0.5.64/28  (16 IPs)  – TGW ENI │
│  Subnet-Prod-ClientVPN-AZ-B  10.0.5.80/27  (32 IPs)  – VPN ENI │
│  Subnet-Prod-Public-AZ-B     10.0.5.112/28 (16 IPs)  – NAT GW  │
│  Subnet-Prod-App-AZ-B        10.0.5.128/25 (128 IPs) – EC2 HIS │
│  Subnet-Prod-DB-AZ-B         10.0.6.0/26   (64 IPs)  – RDS     │
└──────────────────────────────────────────────────────────────────┘
```

#### 2.1 – VPC Production
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_vpc` | `cidr_block` | `10.0.4.0/22` |
| | `enable_dns_support` | `true` |
| | `enable_dns_hostnames` | `true` |
| | `tags.Name` | `VPC-Production` |

#### 2.2 – Internet Gateway (chỉ dùng cho NAT GW outbound – không public inbound)
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_internet_gateway` | `vpc_id` | ID VPC Production |
| | `tags.Name` | `IGW-Production` |

> **Quan trọng:** IGW này chỉ phục vụ NAT Gateway (outbound). Không có resource nào trong VPC Production được gán Public IP, và Security Group không mở inbound từ `0.0.0.0/0`.

#### 2.3 – Subnets (10 subnets – 5 loại × 2 AZ)

| Tên Subnet | AZ | CIDR | `map_public_ip_on_launch` | Mục đích |
|------------|----|------|--------------------------|----------|
| `Subnet-Prod-TGW-AZ-A` | AZ-a | `10.0.4.0/28` | `false` | ENI của TGW Attachment |
| `Subnet-Prod-TGW-AZ-B` | AZ-b | `10.0.5.64/28` | `false` | ENI của TGW Attachment |
| `Subnet-Prod-ClientVPN-AZ-A` | AZ-a | `10.0.4.16/27` | `false` | ENI của Client VPN Endpoint |
| `Subnet-Prod-ClientVPN-AZ-B` | AZ-b | `10.0.5.80/27` | `false` | ENI của Client VPN Endpoint |
| `Subnet-Prod-Public-AZ-A` | AZ-a | `10.0.4.48/28` | `false` | NAT Gateway (không cần public IP, NAT GW dùng EIP riêng) |
| `Subnet-Prod-Public-AZ-B` | AZ-b | `10.0.5.112/28` | `false` | NAT Gateway |
| `Subnet-Prod-App-AZ-A` | AZ-a | `10.0.4.64/25` | `false` | EC2 App Server HIS, Internal ALB |
| `Subnet-Prod-App-AZ-B` | AZ-b | `10.0.5.128/25` | `false` | EC2 App Server HIS, Internal ALB |
| `Subnet-Prod-DB-AZ-A` | AZ-a | `10.0.5.0/26` | `false` | RDS Primary |
| `Subnet-Prod-DB-AZ-B` | AZ-b | `10.0.6.0/26` | `false` | RDS Standby (Multi-AZ) |

> Cấu hình mỗi `aws_subnet`: `vpc_id`, `cidr_block`, `availability_zone`, `map_public_ip_on_launch`, `tags.Name`.

#### 2.4 – Elastic IP cho NAT Gateway (2 EIP – 1 mỗi AZ)
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_eip` (x2) | `domain` | `"vpc"` |
| | `tags.Name` | `EIP-NatGW-Prod-AZ-A` / `EIP-NatGW-Prod-AZ-B` |

#### 2.5 – NAT Gateway (2 NAT GW – 1 mỗi AZ, đảm bảo HA)
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_nat_gateway` | `allocation_id` | ID EIP AZ-A |
| | `subnet_id` | `Subnet-Prod-Public-AZ-A` |
| | `connectivity_type` | `"public"` |
| | `tags.Name` | `NatGW-Prod-AZ-A` |
| `aws_nat_gateway` | `allocation_id` | ID EIP AZ-B |
| | `subnet_id` | `Subnet-Prod-Public-AZ-B` |
| | `connectivity_type` | `"public"` |
| | `tags.Name` | `NatGW-Prod-AZ-B` |

> NAT Gateway phụ thuộc vào IGW. Thêm `depends_on = [aws_internet_gateway.prod]`.

#### 2.6 – DB Subnet Group (cho RDS Multi-AZ)
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_db_subnet_group` | `name` | `"prod-db-subnet-group"` |
| | `subnet_ids` | `[Subnet-Prod-DB-AZ-A, Subnet-Prod-DB-AZ-B]` |
| | `tags.Name` | `DB-Subnet-Group-Production` |

---

## MODULE 03 – TRANSIT GATEWAY

### Mục tiêu
Tạo AWS Transit Gateway làm router trung tâm. Chỉ có **1 VPC Attachment** (VPC Production) và **2 VPN Attachment** (2 bệnh viện). Quản lý Route Table TGW thủ công để kiểm soát định tuyến chính xác.

#### 3.1 – Transit Gateway
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_ec2_transit_gateway` | `description` | `"Central Router – Hospital Network"` |
| | `amazon_side_asn` | `64512` |
| | `auto_accept_shared_attachments` | `"disable"` |
| | `default_route_table_association` | `"disable"` |
| | `default_route_table_propagation` | `"disable"` |
| | `dns_support` | `"enable"` |
| | `vpn_ecmp_support` | `"enable"` |
| | `tags.Name` | `TGW-Hospital` |

#### 3.2 – TGW VPC Attachment – VPC Production (duy nhất)
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_ec2_transit_gateway_vpc_attachment` | `transit_gateway_id` | ID TGW |
| | `vpc_id` | ID VPC Production |
| | `subnet_ids` | `[Subnet-Prod-TGW-AZ-A, Subnet-Prod-TGW-AZ-B]` |
| | `dns_support` | `"enable"` |
| | `transit_gateway_default_route_table_association` | `false` |
| | `transit_gateway_default_route_table_propagation` | `false` |
| | `tags.Name` | `TGW-Attach-VPC-Production` |

> **Lưu ý:** TGW Attachment VPN cho 2 bệnh viện sẽ được tạo tự động khi tạo `aws_vpn_connection` ở Module 04.

#### 3.3 – TGW Route Tables (2 bảng riêng biệt)

**Route Table 1: dành cho VPN OnPremise (2 bệnh viện)**
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_ec2_transit_gateway_route_table` | `transit_gateway_id` | ID TGW |
| | `tags.Name` | `TGW-RT-OnPremise` |

**Route Table 2: dành cho VPC Production**
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_ec2_transit_gateway_route_table` | `transit_gateway_id` | ID TGW |
| | `tags.Name` | `TGW-RT-Production` |

#### 3.4 – TGW Route Table Associations
| Resource | Attachment | Route Table gán vào |
|----------|-----------|---------------------|
| `aws_ec2_transit_gateway_route_table_association` | VPN Attachment BV-1 *(sau khi tạo VPN Connection)* | `TGW-RT-OnPremise` |
| `aws_ec2_transit_gateway_route_table_association` | VPN Attachment BV-2 | `TGW-RT-OnPremise` |
| `aws_ec2_transit_gateway_route_table_association` | VPC Production Attachment | `TGW-RT-Production` |

#### 3.5 – TGW Static Routes

**Trong `TGW-RT-OnPremise` (bệnh viện muốn đi đâu):**
| Resource | `destination_cidr_block` | `transit_gateway_attachment_id` | Ý nghĩa |
|----------|--------------------------|--------------------------------|---------|
| `aws_ec2_transit_gateway_route` | `10.0.4.0/22` | TGW-Attach-VPC-Production | Bệnh viện → VPC Production |

**Trong `TGW-RT-Production` (Production muốn đi đâu):**
| Resource | `destination_cidr_block` | `transit_gateway_attachment_id` | Ý nghĩa |
|----------|--------------------------|--------------------------------|---------|
| `aws_ec2_transit_gateway_route` | `192.168.10.0/24` | VPN Attachment BV-1 | Production → Bệnh viện 1 |
| `aws_ec2_transit_gateway_route` | `192.168.20.0/24` | VPN Attachment BV-2 | Production → Bệnh viện 2 |

> **Bảo mật định tuyến:** BV-1 và BV-2 **không thể kết nối chéo với nhau** – mỗi bệnh viện chỉ thấy route tới VPC Production, không thấy route tới bệnh viện còn lại.

---

## MODULE 04 – SITE-TO-SITE VPN (2 Bệnh viện)

### Mục tiêu
Tạo kết nối IPsec VPN mã hóa từ 2 bệnh viện vào Transit Gateway. Mỗi kết nối có 2 tunnel để đảm bảo HA.

### Lặp lại cho: `hospital-1`, `hospital-2`

#### 4.1 – Customer Gateway (CGW)
| Resource | Tham số | Giá trị BV-1 / BV-2 |
|----------|---------|----------------------|
| `aws_customer_gateway` | `bgp_asn` | `65001` / `65002` |
| | `ip_address` | EIP của EC2 VPN Appliance BV-1 / BV-2 |
| | `type` | `"ipsec.1"` |
| | `tags.Name` | `CGW-Hospital-1` / `CGW-Hospital-2` |

> `ip_address` phụ thuộc vào EIP từ Module 01. Dùng `depends_on` hoặc tham chiếu output.

#### 4.2 – VPN Connection (Site-to-Site)
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_vpn_connection` | `customer_gateway_id` | ID CGW tương ứng |
| | `transit_gateway_id` | ID TGW |
| | `type` | `"ipsec.1"` |
| | `static_routes_only` | `true` |
| | `tunnel1_ike_versions` | `["ikev2"]` |
| | `tunnel1_phase1_encryption_algorithms` | `["AES256"]` |
| | `tunnel1_phase1_integrity_algorithms` | `["SHA2-256"]` |
| | `tunnel1_phase1_dh_group_numbers` | `[14]` |
| | `tunnel1_phase2_encryption_algorithms` | `["AES256"]` |
| | `tunnel1_phase2_integrity_algorithms` | `["SHA2-256"]` |
| | `tunnel1_phase2_dh_group_numbers` | `[14]` |
| | `tunnel2_*` | *(cấu hình tương tự tunnel1 – dự phòng HA)* |
| | `tags.Name` | `VPN-Hospital-1` / `VPN-Hospital-2` |

#### 4.3 – VPN Static Routes
| Resource | Tham số | Giá trị BV-1 / BV-2 |
|----------|---------|----------------------|
| `aws_vpn_connection_route` | `destination_cidr_block` | `192.168.10.0/24` / `192.168.20.0/24` |
| | `vpn_connection_id` | ID VPN Connection tương ứng |

#### 4.4 – Outputs cần export (dùng để cấu hình StrongSwan)
| Output | Giá trị |
|--------|---------|
| `vpn_hospital_1_tunnel1_address` | `aws_vpn_connection.hospital_1.tunnel1_address` |
| `vpn_hospital_1_tunnel1_preshared_key` | `aws_vpn_connection.hospital_1.tunnel1_preshared_key` *(sensitive)* |
| `vpn_hospital_1_tunnel2_address` | `aws_vpn_connection.hospital_1.tunnel2_address` |
| `vpn_hospital_1_tunnel2_preshared_key` | `aws_vpn_connection.hospital_1.tunnel2_preshared_key` *(sensitive)* |
| *(tương tự cho hospital_2)* | |

---

## MODULE 05 – AWS CLIENT VPN (Bác sĩ từ xa)

### Mục tiêu
Cho phép bác sĩ kết nối từ thiết bị cá nhân qua Internet vào VPC Production một cách an toàn. Endpoint Client VPN được đặt trong **Subnet-Prod-ClientVPN** của VPC Production.

#### 5.1 – ACM Certificates (Mutual TLS)

> **Bước chuẩn bị ngoài Terraform:** Dùng `easy-rsa` tạo CA + Server Certificate + Client Certificate. Sau đó import vào ACM bằng `aws_acm_certificate` (hoặc `aws acm import-certificate` CLI).

| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_acm_certificate` (Server) | `private_key` | Nội dung file server.key |
| | `certificate_body` | Nội dung file server.crt |
| | `certificate_chain` | Nội dung file ca.crt |
| | `tags.Name` | `ClientVPN-Server-Cert` |
| `aws_acm_certificate` (Client CA) | `certificate_body` | Nội dung file ca.crt *(chỉ cần cert của CA client)* |
| | `tags.Name` | `ClientVPN-Client-CA-Cert` |

#### 5.2 – CloudWatch Log Group cho Client VPN
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_cloudwatch_log_group` | `name` | `"/hospital/clientvpn/connections"` |
| | `retention_in_days` | `90` |
| | `kms_key_id` | ARN KMS Key |

#### 5.3 – Client VPN Endpoint
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_ec2_client_vpn_endpoint` | `description` | `"Doctor Remote Access VPN"` |
| | `server_certificate_arn` | ARN Server Cert từ ACM |
| | `client_cidr_block` | `"10.0.200.0/22"` *(dải IP cấp cho bác sĩ, phải ≥ /22, không chồng lấn với VPC)* |
| | `authentication_options[0].type` | `"certificate-authentication"` |
| | `authentication_options[0].root_certificate_chain_arn` | ARN Client CA Cert |
| | `connection_log_options.enabled` | `true` |
| | `connection_log_options.cloudwatch_log_group` | `/hospital/clientvpn/connections` |
| | `split_tunnel` | `true` *(chỉ traffic đến AWS đi qua VPN – không ảnh hưởng Internet cá nhân bác sĩ)* |
| | `vpc_id` | ID VPC Production |
| | `security_group_ids` | `[SG-ClientVPN-Endpoint]` |
| | `dns_servers` | `["10.0.4.x"]` *(tùy chọn – DNS của Route53 Resolver trong VPC)* |
| | `tags.Name` | `ClientVPN-Doctor-Remote` |

#### 5.4 – Client VPN Network Associations (2 AZ)
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_ec2_client_vpn_network_association` | `client_vpn_endpoint_id` | ID Endpoint |
| | `subnet_id` | `Subnet-Prod-ClientVPN-AZ-A` |
| `aws_ec2_client_vpn_network_association` | `client_vpn_endpoint_id` | ID Endpoint |
| | `subnet_id` | `Subnet-Prod-ClientVPN-AZ-B` |

#### 5.5 – Client VPN Authorization Rules
| Resource | `target_network_cidr` | `authorize_all_groups` | Mô tả |
|----------|----------------------|----------------------|-------|
| `aws_ec2_client_vpn_authorization_rule` | `10.0.4.64/25` | `true` | Cho phép vào App Subnet AZ-A (HIS) |
| `aws_ec2_client_vpn_authorization_rule` | `10.0.5.128/25` | `true` | Cho phép vào App Subnet AZ-B (HIS) |

> **Không tạo rule** cho DB Subnet, TGW Subnet, hay `0.0.0.0/0` → bác sĩ không thể truy cập DB trực tiếp hoặc ra Internet qua VPN.

---

## MODULE 06 – ROUTE TABLES

### Mục tiêu
Cấu hình định tuyến cho toàn hệ thống. Mỗi loại subnet có Route Table riêng để kiểm soát luồng traffic độc lập.

### Phía VPC OnPremise (x2 bệnh viện)

#### 6.1 – Route Table: Public Subnet OnPremise (VPN Appliance ra Internet)
| Route | Next Hop |
|-------|----------|
| `0.0.0.0/0` | Internet Gateway của VPC OnPremise |

> Gắn vào: `Subnet-OnPremise-Public-1` và `Subnet-OnPremise-Public-2`

#### 6.2 – Route Table: Private Subnet OnPremise (Workstation → AWS qua StrongSwan)
| Route | Next Hop |
|-------|----------|
| `10.0.4.0/22` | ENI của EC2 VPN Appliance (instance_id hoặc network_interface_id) |

> Gắn vào: `Subnet-OnPremise-Private-1` và `Subnet-OnPremise-Private-2`

---

### Phía VPC Production

#### 6.3 – Route Table: Public Subnet (NAT GW → Internet)
| Route | Next Hop |
|-------|----------|
| `0.0.0.0/0` | Internet Gateway Production |

> Gắn vào: `Subnet-Prod-Public-AZ-A`, `Subnet-Prod-Public-AZ-B`

#### 6.4 – Route Table: TGW Subnet (traffic từ bệnh viện vào phân phối tiếp)
| Route | Next Hop |
|-------|----------|
| *(Local only)* | VPC Local |

> Subnet này chỉ nhận traffic từ TGW Attachment ENI. Không cần route bổ sung – traffic đã được định tuyến bởi TGW Route Table ở Module 03.

#### 6.5 – Route Table: Client VPN Subnet
| Route | Next Hop |
|-------|----------|
| *(Local only)* | VPC Local |

> Tương tự TGW Subnet – AWS Client VPN tự xử lý định tuyến nội bộ.

#### 6.6 – Route Table: App Subnet AZ-A (EC2 HIS ra Internet qua NAT)
| Route | Next Hop | Lý do |
|-------|----------|-------|
| `0.0.0.0/0` | `NatGW-Prod-AZ-A` | Cập nhật phần mềm, tải package |
| `192.168.10.0/24` | TGW Attachment Production | Phản hồi traffic từ BV-1 |
| `192.168.20.0/24` | TGW Attachment Production | Phản hồi traffic từ BV-2 |

> Gắn vào: `Subnet-Prod-App-AZ-A`

#### 6.7 – Route Table: App Subnet AZ-B
| Route | Next Hop |
|-------|----------|
| `0.0.0.0/0` | `NatGW-Prod-AZ-B` |
| `192.168.10.0/24` | TGW Attachment Production |
| `192.168.20.0/24` | TGW Attachment Production |

> Gắn vào: `Subnet-Prod-App-AZ-B`

#### 6.8 – Route Table: DB Subnet (Isolated – không có route ra ngoài)
| Route | Next Hop |
|-------|----------|
| *(VPC Local only – mặc định)* | – |

> **Không thêm bất kỳ route nào.** DB Subnet chỉ nhận traffic từ App Subnet nội bộ thông qua Security Group. Đây là tầng bảo mật cao nhất.

> Gắn vào: `Subnet-Prod-DB-AZ-A`, `Subnet-Prod-DB-AZ-B`

---

## MODULE 07 – SECURITY GROUPS & NACLs

### Mục tiêu
Kiểm soát traffic Layer 4 (SG) và Layer 3 (NACL) theo nguyên tắc Least Privilege. Tất cả SG đều thuộc VPC Production (trừ SG OnPremise ở Module 01).

#### 7.1 – Security Group: Client VPN Endpoint
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_security_group` | `name` | `sg-clientvpn-endpoint` |
| | `vpc_id` | VPC Production |
| Inbound UDP 443 | Source | `0.0.0.0/0` *(bác sĩ kết nối từ Internet)* |
| Outbound TCP 443/8080 | Destination | `SG-App-Server` |

#### 7.2 – Security Group: Internal ALB
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_security_group` | `name` | `sg-alb-internal` |
| | `vpc_id` | VPC Production |
| Inbound HTTPS 443 | Source | `192.168.10.0/24` *(BV-1)* |
| Inbound HTTPS 443 | Source | `192.168.20.0/24` *(BV-2)* |
| Inbound HTTPS 443 | Source | `10.0.200.0/22` *(Client VPN – bác sĩ)* |
| Inbound HTTP 80 | Source | *(như trên – redirect sang 443)* |
| Outbound TCP 8080 | Destination | `SG-App-Server` |

#### 7.3 – Security Group: App Server EC2 (HIS)
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_security_group` | `name` | `sg-app-server` |
| | `vpc_id` | VPC Production |
| Inbound TCP 8080 | Source | `SG-ALB-Internal` *(chỉ từ ALB)* |
| Inbound SSH 22 | Source | `SG-Bastion` *(nếu có Bastion)* |
| Outbound TCP 3306 hoặc 5432 | Destination | `SG-RDS` |
| Outbound HTTPS 443 | Destination | `0.0.0.0/0` *(NAT GW → Internet cho cập nhật)* |
| Outbound HTTPS 443 | Destination | `SG-VPC-Endpoints` *(S3, KMS, Secrets Manager)* |

#### 7.4 – Security Group: RDS Database (Isolated)
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_security_group` | `name` | `sg-rds-prod` |
| | `vpc_id` | VPC Production |
| Inbound TCP 3306 *(MySQL)* hoặc 5432 *(PostgreSQL)* | Source | `SG-App-Server` **only** |
| Outbound | *(Không có rule outbound)* | – |

#### 7.5 – Security Group: Bastion Host (tùy chọn – trong Public Subnet)
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_security_group` | `name` | `sg-bastion-prod` |
| | `vpc_id` | VPC Production |
| Inbound SSH 22 | Source | IP quản trị IT cụ thể |
| Outbound SSH 22 | Destination | `SG-App-Server` |

> **Thay thế bằng AWS SSM Session Manager** để không cần mở port 22 – yêu cầu IAM Instance Profile có `AmazonSSMManagedInstanceCore`.

#### 7.6 – Security Group: VPC Endpoints (Interface Endpoints)
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_security_group` | `name` | `sg-vpc-endpoints` |
| | `vpc_id` | VPC Production |
| Inbound HTTPS 443 | Source | `SG-App-Server` |
| Outbound All | Destination | `0.0.0.0/0` |

#### 7.7 – NACL: DB Subnet (tầng bảo vệ thứ 2 cho database)
| Rule # | Direction | Protocol | Port | Source/Dest | Action |
|--------|-----------|----------|------|-------------|--------|
| 100 | Inbound | TCP | 3306/5432 | `10.0.4.64/25` (App AZ-A) | ALLOW |
| 110 | Inbound | TCP | 3306/5432 | `10.0.5.128/25` (App AZ-B) | ALLOW |
| 200 | Inbound | ALL | ALL | `0.0.0.0/0` | DENY |
| 100 | Outbound | TCP | 1024-65535 | `10.0.4.64/25` | ALLOW |
| 110 | Outbound | TCP | 1024-65535 | `10.0.5.128/25` | ALLOW |
| 200 | Outbound | ALL | ALL | `0.0.0.0/0` | DENY |

> Gắn vào: `Subnet-Prod-DB-AZ-A`, `Subnet-Prod-DB-AZ-B`

---

## MODULE 08 – COMPUTE EC2

### Mục tiêu
Triển khai EC2: VPN Appliance (phía OnPremise × 2), App Server (VPC Production × 2 AZ), và tùy chọn Bastion Host.

#### 8.1 – EC2 VPN Appliance (OnPremise – x2)

| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_instance` (x2) | `ami` | Ubuntu 22.04 LTS (`ami-0df7a207adb9748c7` – ap-southeast-1, kiểm tra lại) |
| | `instance_type` | `t3.micro` |
| | `subnet_id` | `Subnet-OnPremise-Public-1` / `Subnet-OnPremise-Public-2` |
| | `vpc_security_group_ids` | `[SG-OnPremise-VPN-Appliance-1]` / `[...-2]` |
| | `source_dest_check` | **`false`** *(bắt buộc – EC2 đóng vai trò router/VPN gateway)* |
| | `key_name` | `hospital-keypair` |
| | `iam_instance_profile` | `profile-ec2-vpn-appliance` *(SSM access)* |
| | `user_data` | `templatefile("scripts/strongswan-init.sh.tpl", {...})` |
| | `tags.Name` | `EC2-VPN-Appliance-Hospital-1` / `-2` |

**`user_data` script mẫu (strongswan-init.sh.tpl):**
```bash
#!/bin/bash
apt-get update -y
apt-get install -y strongswan strongswan-pki libcharon-extra-plugins
# Bật IP forwarding
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p
# Các tham số tunnel được inject qua templatefile():
# ${tunnel1_address}, ${tunnel1_psk}, ${tunnel2_address}, ${tunnel2_psk}
# ${local_cidr}, ${remote_cidr}
# Ghi file /etc/ipsec.conf và /etc/ipsec.secrets tại đây
```

#### 8.2 – EIP Association cho VPN Appliance
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_eip_association` (x2) | `instance_id` | ID EC2 VPN Appliance BV-1 / BV-2 |
| | `allocation_id` | ID EIP BV-1 / BV-2 |

#### 8.3 – EC2 App Server HIS (VPC Production – 2 AZ)
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_instance` (x2) | `ami` | Amazon Linux 2023 (`ami-0c1907b6d35db1f5d` – ap-southeast-1) |
| | `instance_type` | `t3.small` |
| | `subnet_id` | `Subnet-Prod-App-AZ-A` / `Subnet-Prod-App-AZ-B` |
| | `vpc_security_group_ids` | `[SG-App-Server]` |
| | `iam_instance_profile` | `profile-ec2-app-server` |
| | `root_block_device.volume_type` | `"gp3"` |
| | `root_block_device.encrypted` | `true` |
| | `root_block_device.kms_key_id` | ARN KMS General Key |
| | `user_data` | Script cài HIS mock app (nginx/Flask) |
| | `tags.Name` | `EC2-AppServer-HIS-AZ-A` / `EC2-AppServer-HIS-AZ-B` |

#### 8.4 – EC2 Bastion Host (tùy chọn – Public Subnet VPC Production)
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_instance` | `ami` | Amazon Linux 2023 |
| | `instance_type` | `t3.micro` |
| | `subnet_id` | `Subnet-Prod-Public-AZ-A` |
| | `vpc_security_group_ids` | `[SG-Bastion]` |
| | `associate_public_ip_address` | `true` |
| | `iam_instance_profile` | `profile-ec2-bastion` |
| | `root_block_device.encrypted` | `true` |
| | `tags.Name` | `EC2-Bastion-Production` |

> **Khuyến nghị:** Thay Bastion bằng **AWS SSM Session Manager** – không cần public IP, không cần mở port 22, an toàn hơn. Chỉ cần IAM Instance Profile có `AmazonSSMManagedInstanceCore`.

#### 8.5 – EC2 Workstation Giả lập (OnPremise Private Subnet – tùy chọn)
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_instance` (x2) | `ami` | Amazon Linux 2023 |
| | `instance_type` | `t3.micro` |
| | `subnet_id` | `Subnet-OnPremise-Private-1` / `-2` |
| | `tags.Name` | `EC2-Workstation-Hospital-1` / `-2` |

#### 8.6 – Key Pair
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_key_pair` | `key_name` | `hospital-keypair` |
| | `public_key` | `file("~/.ssh/hospital_key.pub")` |

---

## MODULE 09 – INTERNAL APPLICATION LOAD BALANCER

### Mục tiêu
Phân tải nội bộ cho 2 App Server HIS. **Internal ALB** – không có IP public, chỉ phục vụ traffic từ bên trong VPC.

#### 9.1 – Internal ALB
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_lb` | `name` | `"alb-internal-prod"` |
| | `internal` | `true` |
| | `load_balancer_type` | `"application"` |
| | `security_groups` | `[SG-ALB-Internal]` |
| | `subnets` | `[Subnet-Prod-App-AZ-A, Subnet-Prod-App-AZ-B]` |
| | `enable_deletion_protection` | `true` |
| | `access_logs.bucket` | S3 bucket ALB logs |
| | `access_logs.enabled` | `true` |
| | `tags.Name` | `ALB-Internal-Production` |

#### 9.2 – Target Group
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_lb_target_group` | `name` | `"tg-his-app"` |
| | `port` | `8080` |
| | `protocol` | `"HTTP"` |
| | `vpc_id` | VPC Production |
| | `target_type` | `"instance"` |
| | `health_check.path` | `"/health"` |
| | `health_check.protocol` | `"HTTP"` |
| | `health_check.interval` | `30` |
| | `health_check.timeout` | `5` |
| | `health_check.healthy_threshold` | `2` |
| | `health_check.unhealthy_threshold` | `3` |

#### 9.3 – Target Group Attachments
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_lb_target_group_attachment` | `target_group_arn` | TG ARN |
| | `target_id` | Instance ID `EC2-AppServer-HIS-AZ-A` |
| | `port` | `8080` |
| `aws_lb_target_group_attachment` | `target_id` | Instance ID `EC2-AppServer-HIS-AZ-B` |
| | `port` | `8080` |

#### 9.4 – ALB Listener: HTTPS 443
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_lb_listener` | `port` | `443` |
| | `protocol` | `"HTTPS"` |
| | `ssl_policy` | `"ELBSecurityPolicy-TLS13-1-2-2021-06"` |
| | `certificate_arn` | ACM Certificate ARN (internal domain) |
| | `default_action.type` | `"forward"` |
| | `default_action.target_group_arn` | TG ARN |

#### 9.5 – ALB Listener: HTTP 80 (redirect)
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_lb_listener` | `port` | `80` |
| | `protocol` | `"HTTP"` |
| | `default_action.type` | `"redirect"` |
| | `default_action.redirect.port` | `"443"` |
| | `default_action.redirect.protocol` | `"HTTPS"` |
| | `default_action.redirect.status_code` | `"HTTP_301"` |

---

## MODULE 10 – DATABASE RDS

### Mục tiêu
Triển khai RDS lưu hồ sơ bệnh nhân trong DB Subnet Isolated. Multi-AZ, mã hóa, backup tự động.

#### 10.1 – RDS Parameter Group
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_db_parameter_group` | `name` | `"hospital-prod-mysql8"` |
| | `family` | `"mysql8.0"` |
| | Parameter `require_secure_transport` | `1` *(bắt buộc kết nối SSL)* |

#### 10.2 – RDS Instance (Multi-AZ)
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_db_instance` | `identifier` | `"hospital-prod-db"` |
| | `engine` | `"mysql"` |
| | `engine_version` | `"8.0.35"` |
| | `instance_class` | `"db.t3.medium"` *(đổi sang `db.t3.micro` để tiết kiệm chi phí dev)* |
| | `allocated_storage` | `100` |
| | `max_allocated_storage` | `500` *(autoscaling storage)* |
| | `storage_type` | `"gp3"` |
| | `storage_encrypted` | `true` |
| | `kms_key_id` | ARN KMS Key RDS |
| | `multi_az` | `true` |
| | `db_subnet_group_name` | `"prod-db-subnet-group"` |
| | `vpc_security_group_ids` | `[SG-RDS-Prod]` |
| | `parameter_group_name` | `"hospital-prod-mysql8"` |
| | `db_name` | `"hospital_emr"` |
| | `username` | `"dbadmin"` |
| | `manage_master_user_password` | `true` *(AWS tự quản lý password qua Secrets Manager)* |
| | `backup_retention_period` | `7` |
| | `backup_window` | `"02:00-04:00"` |
| | `maintenance_window` | `"Mon:04:00-Mon:06:00"` |
| | `deletion_protection` | `true` |
| | `skip_final_snapshot` | `false` |
| | `final_snapshot_identifier` | `"hospital-prod-db-final-snapshot"` |
| | `performance_insights_enabled` | `true` |
| | `performance_insights_kms_key_id` | ARN KMS Key RDS |
| | `enabled_cloudwatch_logs_exports` | `["error", "general", "slowquery"]` |
| | `tags.Name` | `RDS-Hospital-Production` |

> `manage_master_user_password = true` yêu cầu Terraform AWS provider ≥ 5.x. AWS sẽ tự tạo và lưu password vào Secrets Manager.

---

## MODULE 11 – STORAGE S3

### Mục tiêu
Tạo các S3 bucket phục vụ lưu trữ dữ liệu y tế, audit logs, và hạ tầng Terraform.

#### 11.1 – S3 Bucket: Dữ liệu Y tế (ảnh X-quang, tài liệu EMR)
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_s3_bucket` | `bucket` | `"hospital-medical-data-${data.aws_caller_identity.current.account_id}"` |
| `aws_s3_bucket_versioning` | `status` | `"Enabled"` |
| `aws_s3_bucket_server_side_encryption_configuration` | `sse_algorithm` | `"aws:kms"` |
| | `kms_master_key_id` | ARN KMS Key S3 |
| `aws_s3_bucket_public_access_block` | Tất cả 4 tham số | `true` |
| `aws_s3_bucket_lifecycle_configuration` | Rule `transition-to-glacier` | After 365 days → `GLACIER` |
| | Rule `expire-noncurrent` | Noncurrent versions expire after 90 days |
| `aws_s3_bucket_policy` | Deny unencrypted uploads | Condition: `s3:x-amz-server-side-encryption != "aws:kms"` |

#### 11.2 – S3 Bucket: CloudTrail Audit Logs
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_s3_bucket` | `bucket` | `"hospital-cloudtrail-logs-${data.aws_caller_identity.current.account_id}"` |
| `aws_s3_bucket_server_side_encryption_configuration` | `sse_algorithm` | `"aws:kms"` |
| `aws_s3_bucket_public_access_block` | Tất cả | `true` |
| `aws_s3_bucket_policy` | Allow CloudTrail PutObject | Principal: `cloudtrail.amazonaws.com` |
| `aws_s3_bucket_lifecycle_configuration` | Transition GLACIER | After 90 days |
| | Expiration | After 2555 days *(7 năm – tiêu chuẩn lưu trữ y tế)* |

#### 11.3 – S3 Bucket: Terraform State
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_s3_bucket` | `bucket` | `"hospital-terraform-state-${data.aws_caller_identity.current.account_id}"` |
| `aws_s3_bucket_versioning` | `status` | `"Enabled"` |
| `aws_s3_bucket_server_side_encryption_configuration` | `sse_algorithm` | `"aws:kms"` |
| `aws_s3_bucket_public_access_block` | Tất cả | `true` |

#### 11.4 – S3 Bucket: ALB Access Logs
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_s3_bucket` | `bucket` | `"hospital-alb-logs-${data.aws_caller_identity.current.account_id}"` |
| `aws_s3_bucket_policy` | Allow ELB service write | Principal: `logdelivery.elasticloadbalancing.amazonaws.com` |
| `aws_s3_bucket_lifecycle_configuration` | Expiration | After 90 days |

#### 11.5 – DynamoDB Table: Terraform State Lock
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_dynamodb_table` | `name` | `"hospital-terraform-lock"` |
| | `billing_mode` | `"PAY_PER_REQUEST"` |
| | `hash_key` | `"LockID"` |
| | Attribute `LockID` | `type = "S"` |

---

## MODULE 12 – AWS KMS

### Mục tiêu
Tạo KMS Keys chuyên dụng cho từng loại dữ liệu. Bật key rotation tự động hàng năm.

#### 12.1 – KMS Key: General (EBS, CloudWatch Logs, SNS)
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_kms_key` | `description` | `"Hospital General Encryption Key – EBS, Logs"` |
| | `deletion_window_in_days` | `30` |
| | `enable_key_rotation` | `true` |
| | `key_policy` | JSON: allow root account + EC2 roles |
| | `tags.Name` | `KMS-Hospital-General` |
| `aws_kms_alias` | `name` | `"alias/hospital-general"` |
| | `target_key_id` | ID KMS Key General |

#### 12.2 – KMS Key: RDS Database
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_kms_key` | `description` | `"Hospital RDS Patient Data Encryption Key"` |
| | `enable_key_rotation` | `true` |
| | `tags.Name` | `KMS-Hospital-RDS` |
| `aws_kms_alias` | `name` | `"alias/hospital-rds"` |

#### 12.3 – KMS Key: S3 Medical Data
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_kms_key` | `description` | `"Hospital S3 Medical Data Encryption Key"` |
| | `enable_key_rotation` | `true` |
| | `tags.Name` | `KMS-Hospital-S3` |
| `aws_kms_alias` | `name` | `"alias/hospital-s3"` |

---

## MODULE 13 – IAM ROLES & POLICIES

### Mục tiêu
Phân quyền tối thiểu (Least Privilege) cho EC2 instances và AWS services.

#### 13.1 – IAM Role: EC2 App Server HIS
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_iam_role` | `name` | `"role-ec2-app-server-his"` |
| | `assume_role_policy` | EC2 service trust policy |
| `aws_iam_role_policy_attachment` | `policy_arn` | `arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore` |
| `aws_iam_policy` (custom) | Allow `s3:GetObject`, `s3:PutObject` | Chỉ bucket `hospital-medical-data-*` |
| | Allow `kms:Decrypt`, `kms:GenerateDataKey` | Chỉ KMS S3 Key |
| | Allow `secretsmanager:GetSecretValue` | Chỉ secret của DB |
| | Allow `logs:PutLogEvents`, `logs:CreateLogStream` | Log Group app server |
| `aws_iam_instance_profile` | `name` | `"profile-ec2-app-server-his"` |

#### 13.2 – IAM Role: EC2 VPN Appliance (OnPremise)
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_iam_role` | `name` | `"role-ec2-vpn-appliance"` |
| `aws_iam_role_policy_attachment` | `policy_arn` | `AmazonSSMManagedInstanceCore` |
| `aws_iam_instance_profile` | `name` | `"profile-ec2-vpn-appliance"` |

#### 13.3 – IAM Role: EC2 Bastion
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_iam_role` | `name` | `"role-ec2-bastion"` |
| `aws_iam_role_policy_attachment` | `policy_arn` | `AmazonSSMManagedInstanceCore` |
| `aws_iam_instance_profile` | `name` | `"profile-ec2-bastion"` |

#### 13.4 – IAM Role: VPC Flow Logs → CloudWatch
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_iam_role` | `name` | `"role-vpc-flowlogs-cloudwatch"` |
| | `assume_role_policy` | `vpc-flow-logs.amazonaws.com` trust policy |
| `aws_iam_policy` (inline) | Allow `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents`, `logs:DescribeLogGroups`, `logs:DescribeLogStreams` | Resource: `*` |

#### 13.5 – IAM Role: CloudTrail → CloudWatch Logs
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_iam_role` | `name` | `"role-cloudtrail-cloudwatch"` |
| | `assume_role_policy` | `cloudtrail.amazonaws.com` trust policy |
| `aws_iam_policy` (inline) | Allow `logs:CreateLogStream`, `logs:PutLogEvents` | Resource: CW Log Group ARN |

---

## MODULE 14 – VPC ENDPOINTS (AWS PrivateLink)

### Mục tiêu
Cho phép EC2 App Server giao tiếp với các dịch vụ AWS (S3, KMS, Secrets Manager, SSM) mà không đi qua Internet. Tất cả Endpoints đều nằm trong **VPC Production**.

#### 14.1 – Gateway Endpoint: S3 *(miễn phí – không tốn tiền)*
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_vpc_endpoint` | `vpc_id` | VPC Production |
| | `service_name` | `"com.amazonaws.ap-southeast-1.s3"` |
| | `vpc_endpoint_type` | `"Gateway"` |
| | `route_table_ids` | `[RT-App-AZ-A, RT-App-AZ-B]` *(Route Table của App Subnet)* |
| | `tags.Name` | `VPCEndpoint-S3-Prod` |

#### 14.2 – Interface Endpoint: KMS
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_vpc_endpoint` | `vpc_id` | VPC Production |
| | `service_name` | `"com.amazonaws.ap-southeast-1.kms"` |
| | `vpc_endpoint_type` | `"Interface"` |
| | `subnet_ids` | `[Subnet-Prod-App-AZ-A, Subnet-Prod-App-AZ-B]` |
| | `security_group_ids` | `[SG-VPC-Endpoints]` |
| | `private_dns_enabled` | `true` |
| | `tags.Name` | `VPCEndpoint-KMS-Prod` |

#### 14.3 – Interface Endpoint: Secrets Manager
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_vpc_endpoint` | `service_name` | `"com.amazonaws.ap-southeast-1.secretsmanager"` |
| | `vpc_endpoint_type` | `"Interface"` |
| | `subnet_ids` | `[Subnet-Prod-App-AZ-A, Subnet-Prod-App-AZ-B]` |
| | `security_group_ids` | `[SG-VPC-Endpoints]` |
| | `private_dns_enabled` | `true` |
| | `tags.Name` | `VPCEndpoint-SecretsManager-Prod` |

#### 14.4 – Interface Endpoints: SSM (cần 3 endpoint cho SSM Session Manager)
| Resource | Service Name | `tags.Name` |
|----------|-------------|-------------|
| `aws_vpc_endpoint` | `com.amazonaws.ap-southeast-1.ssm` | `VPCEndpoint-SSM-Prod` |
| `aws_vpc_endpoint` | `com.amazonaws.ap-southeast-1.ssmmessages` | `VPCEndpoint-SSMMessages-Prod` |
| `aws_vpc_endpoint` | `com.amazonaws.ap-southeast-1.ec2messages` | `VPCEndpoint-EC2Messages-Prod` |

> Tất cả SSM endpoints: `vpc_endpoint_type = "Interface"`, `subnet_ids = [App-AZ-A, App-AZ-B]`, `security_group_ids = [SG-VPC-Endpoints]`, `private_dns_enabled = true`.

---

## MODULE 15 – DNS ROUTE 53

### Mục tiêu
Cấu hình Private Hosted Zone cho tên miền nội bộ `hospital.internal` và health check cho HIS endpoint. Zone chỉ associate với **VPC Production** duy nhất.

#### 15.1 – Private Hosted Zone
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_route53_zone` | `name` | `"hospital.internal"` |
| | `comment` | `"Internal DNS for Hospital HIS System"` |
| | `vpc { vpc_id }` | ID VPC Production |
| | `tags.Name` | `PrivateZone-hospital.internal` |

#### 15.2 – DNS Records
| Resource | Record Name | Type | Value |
|----------|------------|------|-------|
| `aws_route53_record` | `his-app.hospital.internal` | `ALIAS` | DNS name của Internal ALB |
| | `db.hospital.internal` | `CNAME` | RDS endpoint (`aws_db_instance.prod.address`) |

#### 15.3 – Health Check cho HIS ALB Endpoint
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_route53_health_check` | `fqdn` | *(IP của ALB hoặc endpoint nội bộ)* |
| | `port` | `443` |
| | `type` | `"HTTPS"` |
| | `resource_path` | `"/health"` |
| | `failure_threshold` | `3` |
| | `request_interval` | `30` |
| | `regions` | `["us-east-1", "eu-west-1", "ap-southeast-1"]` *(Route53 HC cần global)* |
| | `tags.Name` | `HC-HIS-ALB-Production` |

> **Lưu ý:** Route 53 Health Check với Internal ALB cần cấu hình thêm CloudWatch Alarm trigger vì Internal ALB không có public IP.

---

## MODULE 16 – MONITORING (CloudWatch, CloudTrail, VPC Flow Logs, SNS)

### Mục tiêu
Giám sát toàn diện, cảnh báo tự động và audit logging. Tập trung vào VPC Production và các VPN connections.

#### 16.1 – CloudTrail (Multi-Region)
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_cloudtrail` | `name` | `"hospital-audit-trail"` |
| | `s3_bucket_name` | Bucket `hospital-cloudtrail-logs-*` |
| | `is_multi_region_trail` | `true` |
| | `enable_log_file_validation` | `true` *(phát hiện giả mạo log)* |
| | `include_global_service_events` | `true` |
| | `kms_key_id` | ARN KMS Key General |
| | `cloud_watch_logs_group_arn` | `${CW_Log_Group_CloudTrail}:*` |
| | `cloud_watch_logs_role_arn` | ARN IAM Role CloudTrail |
| Event Selector Data | `type = "AWS::S3::Object"` | `values = ["arn:aws:s3:::hospital-medical-data-*/"]` |
| | `type = "AWS::RDS::DBInstance"` | `values = ["arn:aws:rds:*"]` |
| | `tags.Name` | `CloudTrail-Hospital-Audit` |

#### 16.2 – CloudWatch Log Groups
| Resource | `name` | `retention_in_days` | Mục đích |
|----------|--------|---------------------|---------|
| `aws_cloudwatch_log_group` | `/hospital/vpc-flowlogs/production` | `90` | Flow Logs VPC Production |
| | `/hospital/vpc-flowlogs/onpremise-1` | `30` | Flow Logs VPC OnPremise-1 *(tùy chọn)* |
| | `/hospital/vpc-flowlogs/onpremise-2` | `30` | Flow Logs VPC OnPremise-2 *(tùy chọn)* |
| | `/hospital/cloudtrail` | `365` | CloudTrail → CW |
| | `/hospital/clientvpn/connections` | `90` | Client VPN connection logs |
| | `/hospital/ec2/appserver` | `30` | Application logs từ HIS app |

> Tất cả Log Groups: `kms_key_id = ARN KMS Key General`.

#### 16.3 – VPC Flow Logs
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_flow_log` | `traffic_type` | `"ALL"` |
| | `vpc_id` | **VPC Production** (bắt buộc) |
| | `iam_role_arn` | ARN IAM Role VPC Flow Logs |
| | `log_destination_type` | `"cloud-watch-logs"` |
| | `log_destination` | ARN CW Log Group `/hospital/vpc-flowlogs/production` |
| | `log_format` | `"${version} ${account-id} ${interface-id} ${srcaddr} ${dstaddr} ${srcport} ${dstport} ${protocol} ${packets} ${bytes} ${start} ${end} ${action} ${log-status} ${pkt-srcaddr} ${pkt-dstaddr}"` |
| | `tags.Name` | `FlowLog-VPC-Production` |

#### 16.4 – SNS Topic (Cảnh báo IT)
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_sns_topic` | `name` | `"hospital-it-alerts"` |
| | `kms_master_key_id` | ARN KMS Key General |
| | `tags.Name` | `SNS-Hospital-Alerts` |
| `aws_sns_topic_subscription` | `protocol` | `"email"` |
| | `endpoint` | `var.admin_email` |

#### 16.5 – CloudWatch Alarms

**Alarm 1: VPN Tunnel Down – BV-1 Tunnel 1**
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_cloudwatch_metric_alarm` | `alarm_name` | `"alarm-vpn-down-hospital1-t1"` |
| | `namespace` | `"AWS/VPN"` |
| | `metric_name` | `"TunnelState"` |
| | `dimensions.VpnId` | ID `aws_vpn_connection.hospital_1` |
| | `dimensions.TunnelIpAddress` | `tunnel1_address` |
| | `statistic` | `"Maximum"` |
| | `period` | `60` |
| | `evaluation_periods` | `3` |
| | `comparison_operator` | `"LessThanThreshold"` |
| | `threshold` | `1` |
| | `alarm_actions` | `[SNS Topic ARN]` |

> Tạo tương tự cho: BV-1 Tunnel 2, BV-2 Tunnel 1, BV-2 Tunnel 2 → **tổng 4 alarm VPN**.

**Alarm 2: ALB Unhealthy Hosts > 0**
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_cloudwatch_metric_alarm` | `alarm_name` | `"alarm-alb-unhealthy-hosts"` |
| | `namespace` | `"AWS/ApplicationELB"` |
| | `metric_name` | `"UnHealthyHostCount"` |
| | `dimensions.LoadBalancer` | ALB ARN suffix |
| | `dimensions.TargetGroup` | TG ARN suffix |
| | `comparison_operator` | `"GreaterThanOrEqualToThreshold"` |
| | `threshold` | `1` |
| | `evaluation_periods` | `2` |
| | `alarm_actions` | `[SNS Topic ARN]` |

**Alarm 3: EC2 App Server CPU > 85%**
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_cloudwatch_metric_alarm` (x2) | `alarm_name` | `"alarm-ec2-appserver-az-a/b-high-cpu"` |
| | `namespace` | `"AWS/EC2"` |
| | `metric_name` | `"CPUUtilization"` |
| | `dimensions.InstanceId` | Instance ID AZ-A / AZ-B |
| | `threshold` | `85` |
| | `alarm_actions` | `[SNS Topic ARN]` |

**Alarm 4: RDS CPU > 80%**
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_cloudwatch_metric_alarm` | `alarm_name` | `"alarm-rds-high-cpu"` |
| | `namespace` | `"AWS/RDS"` |
| | `metric_name` | `"CPUUtilization"` |
| | `dimensions.DBInstanceIdentifier` | `"hospital-prod-db"` |
| | `threshold` | `80` |
| | `alarm_actions` | `[SNS Topic ARN]` |

**Alarm 5: RDS Free Storage < 10 GB**
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_cloudwatch_metric_alarm` | `alarm_name` | `"alarm-rds-low-storage"` |
| | `metric_name` | `"FreeStorageSpace"` |
| | `threshold` | `10737418240` *(10 GB tính bằng bytes)* |
| | `comparison_operator` | `"LessThanThreshold"` |
| | `alarm_actions` | `[SNS Topic ARN]` |

**Alarm 6: RDS DB Connections > 80**
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_cloudwatch_metric_alarm` | `alarm_name` | `"alarm-rds-high-connections"` |
| | `metric_name` | `"DatabaseConnections"` |
| | `threshold` | `80` |
| | `comparison_operator` | `"GreaterThanThreshold"` |

#### 16.6 – CloudWatch Dashboard
| Resource | Tham số | Giá trị |
|----------|---------|---------|
| `aws_cloudwatch_dashboard` | `dashboard_name` | `"Hospital-IT-Operations"` |
| | `dashboard_body` | JSON với các widget: |
| | | – VPN Tunnel State (4 tunnel × 2 BV) |
| | | – ALB Request Count & Latency |
| | | – ALB Healthy/Unhealthy Host Count |
| | | – EC2 CPU Utilization (2 instance) |
| | | – RDS CPU, Connections, Free Storage |
| | | – VPC Flow Log – Rejected Connections |

---

## TỔNG HỢP CHECKLIST TRIỂN KHAI

### Thứ tự triển khai khuyến nghị

```
Bước 1:  module/kms                ← KMS Keys phải có trước (các module sau phụ thuộc)
Bước 2:  module/iam                ← IAM Roles, Profiles cho EC2 và services
Bước 3:  module/storage_s3         ← S3 Buckets (CloudTrail, ALB logs cần bucket có sẵn)
Bước 4:  module/vpc_onpremise      ← 2 VPC OnPremise + IGW + Subnets + SG
Bước 5:  module/vpc_production      ← VPC Production + 10 Subnets + IGW + NAT GW + DB Subnet Group
Bước 6:  module/security_groups    ← Tất cả SG trong VPC Production (cần VPC ID)
Bước 7:  module/transit_gateway    ← TGW + VPC Attachment (cần VPC Prod + TGW Subnets)
Bước 8:  module/compute_ec2        ← EC2 VPN Appliance trước (cần EIP để tạo CGW)
Bước 9:  module/vpn_site_to_site   ← CGW + VPN Connection (cần EIP từ EC2, TGW ID)
Bước 10: module/route_tables       ← Route Tables (cần TGW ID, NAT GW ID, VPN Attachment ID)
Bước 11: module/vpn_client         ← Client VPN Endpoint (cần VPC, Subnet, ACM Certs, SG)
Bước 12: module/compute_ec2        ← EC2 App Server (sau khi Route Tables sẵn sàng)
Bước 13: module/load_balancer      ← Internal ALB + Target Group + Listener (cần EC2, SG)
Bước 14: module/database_rds       ← RDS (cần DB Subnet Group, SG, KMS)
Bước 15: module/vpc_endpoints      ← VPC Endpoints (cần VPC, Subnet, SG App Server)
Bước 16: module/dns_route53        ← Route53 (cần ALB DNS name, RDS endpoint)
Bước 17: module/monitoring         ← CloudWatch, CloudTrail, Flow Logs, SNS (cần tất cả resource ID)
```

### Outputs quan trọng cần export

| Output | Từ Module | Dùng cho |
|--------|-----------|---------|
| `vpn_hospital_1_tunnel1_address` | `vpn_site_to_site` | Cấu hình StrongSwan BV-1 |
| `vpn_hospital_1_tunnel1_preshared_key` | `vpn_site_to_site` | Cấu hình StrongSwan BV-1 |
| `vpn_hospital_1_tunnel2_address` | `vpn_site_to_site` | StrongSwan BV-1 dự phòng |
| `vpn_hospital_1_tunnel2_preshared_key` | `vpn_site_to_site` | StrongSwan BV-1 dự phòng |
| *(tương tự x4 cho hospital_2)* | | |
| `tgw_id` | `transit_gateway` | Route Tables |
| `tgw_vpc_attachment_id` | `transit_gateway` | TGW Route Table Association |
| `alb_dns_name` | `load_balancer` | Route53 ALIAS record |
| `rds_endpoint` | `database_rds` | App Server config, Route53 CNAME |
| `nat_gw_az_a_id` | `vpc_production` | Route Tables App Subnet |
| `nat_gw_az_b_id` | `vpc_production` | Route Tables App Subnet |
| `client_vpn_endpoint_id` | `vpn_client` | Download `.ovpn` config |
| `kms_key_general_arn` | `kms` | EBS, Logs, SNS encryption |
| `kms_key_rds_arn` | `kms` | RDS encryption |
| `kms_key_s3_arn` | `kms` | S3 encryption |

### Lưu ý triển khai quan trọng

> ⚠️ **`source_dest_check = false`:** EC2 VPN Appliance **bắt buộc** phải tắt `source_dest_check`. Không tắt thì StrongSwan không forward được packet giữa tunnel và mạng nội bộ.

> ⚠️ **StrongSwan cấu hình sau Terraform:** Sau `terraform apply`, lấy `tunnel1_address`, `tunnel1_preshared_key` từ output để cấu hình `/etc/ipsec.conf` và `/etc/ipsec.secrets`. Có thể tự động hóa qua `user_data` + `templatefile()` nếu muốn zero-touch.

> ⚠️ **Client VPN Certificate:** Tạo CA + certs bằng `easy-rsa` trước khi chạy Terraform. Import vào ACM bằng `aws acm import-certificate`. Đây là bước ngoài Terraform không thể tự động hóa hoàn toàn.

> ⚠️ **Client VPN Subnet tối thiểu /27:** AWS yêu cầu subnet gắn với Client VPN Endpoint phải có CIDR tối thiểu `/27` (32 IPs). Đã cấu hình đúng trong Module 02.

> ⚠️ **NAT Gateway phụ thuộc IGW:** Terraform cần `depends_on = [aws_internet_gateway.prod]` cho NAT Gateway resource để tránh race condition.

> ⚠️ **Chi phí chú ý (học tập):** Các dịch vụ tốn phí nhất: NAT Gateway (×2), TGW, Client VPN Endpoint, RDS Multi-AZ, Interface VPC Endpoints. Để tiết kiệm: dùng 1 NAT GW, `db.t3.micro` non-MultiAZ, bỏ Interface Endpoints (dùng NAT GW thay thế).