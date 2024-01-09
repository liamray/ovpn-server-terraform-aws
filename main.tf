terraform {
  required_version = "1.6.6"

  required_providers {
    aws = {
      version = "5.31.0"
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.region
}


locals {
  tags = {
    app = "ovpn-server"
  }
  ovpn_remote_dir      = "/home/ubuntu/ovpn-files"
  ovpn_local_dir       = "${path.module}/output"
  ssh_private_key_file = "${local.ovpn_local_dir}/private-key"
}