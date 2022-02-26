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

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.exercise_name
  cidr = var.cidr

  azs             = var.azs
  private_subnets = var.private_subnets

}

data "aws_ssm_parameter" "home_ip" {
  name = "home_ip"

}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


resource "aws_internet_gateway" "igw" {
  vpc_id = module.vpc.vpc_id

}


# internet route
resource "aws_route" "internet" {
  for_each =  { for rt in module.vpc.private_route_table_ids : rt => rt }   # module.vpc.private_route_table_ids
  route_table_id            = each.value
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id

}


resource "aws_instance" "ec2_vpngw" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = var.ssh_keyname
  subnet_id              = module.vpc.private_subnets[0] # plonk it whereever...
  vpc_security_group_ids = [aws_security_group.sg_clientsite.id]

}

# needed to allow the EC2 instance enough time to come online before adding the EIP to it
resource "time_sleep" "ec2_vpngw_sleep" {
  create_duration = "60s"

  triggers = {
    id = aws_instance.ec2_vpngw.id
  }
}

resource "aws_eip" "vpngw" {
  instance = time_sleep.ec2_vpngw_sleep.triggers["id"]
  #aws_instance.ec2_vpngw.id
  vpc = true
  tags = {
    project      = "iac-exercises"
    iac-exercise = var.exercise_name
    vpn-gw       = "true"

  }

}

resource "aws_security_group" "sg_clientsite" {
  name        = "SG for clientsite VPC"
  description = "SG for clientsite VPC"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "ssh from home"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.aws_ssm_parameter.home_ip.value]
  }

  ingress {
    description = "allow any from the cloud site"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cloudsite_cidr]
  }
  

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}