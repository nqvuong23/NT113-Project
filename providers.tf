terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket = "nqvuong23-terraform-project"
    key    = "nt113/terraform.tfstate"
    region = "ap-southeast-1"

    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = var.aws_region
}
