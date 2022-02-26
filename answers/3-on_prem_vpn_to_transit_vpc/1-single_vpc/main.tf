provider "aws" {
        profile = "default"
        region = "ap-southeast-2"
        access_key = var.aws_access_key_id
        secret_key = var.aws_secret_access_key
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.exercise_name
  cidr = var.cidr

  azs             = var.azs
  private_subnets = var.private_subnets

#  enable_nat_gateway = true
#  enable_vpn_gateway = true

  tags = {
    project = "iac-exercises"
    iac-exercise = var.exercise_name
  }
}

output "new_vpc_id" {
  value = module.vpc.vpc_id
}

output "new_subnet_ids" {
  value = module.vpc.private_subnets
}
