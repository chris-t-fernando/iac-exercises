terraform {

  backend "remote" {
    organization = "diamonds-ro-lt"

    workspaces {
      name = "iac-exercises-3-on_prem_vpn_to_transit_vpc"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4"
    }
  }

  required_version = "~> 1.1"

}