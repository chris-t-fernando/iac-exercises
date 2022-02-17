provider "aws" {
        profile = "default"
        region = "ap-southeast-2"
        access_key = var.aws_access_key_id
        secret_key = var.aws_secret_access_key
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "iac-1-single_vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

#  enable_nat_gateway = true
#  enable_vpn_gateway = true

  tags = {
    project = "iac-exercises"
    iac-exercise = "1-single_vpc"
  }
}