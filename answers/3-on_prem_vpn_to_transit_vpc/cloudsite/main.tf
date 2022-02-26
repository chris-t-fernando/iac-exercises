provider "aws" {
  profile    = "default"
  region     = "ap-southeast-2"
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key

  default_tags {
    tags = {
      project      = "iac-exercises"
      iac-exercise = var.exercise_name

    }
  }

}

# get EIP attached to my EC2 instance
data "aws_eip" "remote_vpn_peer" {
  tags = {
    project = "iac-exercises"
    vpn-gw = "true"
  }
}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.exercise_name
  cidr = var.cidr

  azs             = var.azs
  private_subnets = var.private_subnets

  tags = {
    project = "iac-exercises"
    iac-exercise = var.exercise_name
  }
}



resource "aws_customer_gateway" "office_cgw" {
  bgp_asn    = 65000
  ip_address = data.aws_eip.remote_vpn_peer.public_ip
  type       = "ipsec.1"

}


resource "aws_ec2_transit_gateway" "cloud_transit_gw" {
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"

}

resource "aws_ec2_transit_gateway_vpc_attachment" "cloud_tgw_attachment" {
  subnet_ids         = module.vpc.private_subnets
  transit_gateway_id = aws_ec2_transit_gateway.cloud_transit_gw.id
  vpc_id             = module.vpc.vpc_id

}

resource "aws_route_table" "cloud_routetable" {
  vpc_id = module.vpc.vpc_id

  route {
    cidr_block = "192.168.1.0/24"
    gateway_id = time_sleep.tgw_sleep.triggers["id"]
  }

}

# sometimes the tgw isn't fully up when the vpn connection tries to associate with it
resource "time_sleep" "tgw_sleep" {
  create_duration = "60s"

  triggers = {
    id = aws_ec2_transit_gateway.cloud_transit_gw.id
  }
}

resource "aws_vpn_connection" "cloud_vpn_connection" {
  customer_gateway_id = aws_customer_gateway.office_cgw.id
  transit_gateway_id  = aws_ec2_transit_gateway.cloud_transit_gw.id
  type                = aws_customer_gateway.office_cgw.type
  tunnel1_inside_cidr = var.tunnel1_inside_cidr
  tunnel2_inside_cidr = var.tunnel2_inside_cidr
  tunnel1_preshared_key = var.tunnel1_psk
  tunnel2_preshared_key = var.tunnel2_psk

}



# output