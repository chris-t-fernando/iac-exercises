variable "aws_access_key_id" {}
variable "aws_secret_access_key" {}
variable "exercise_name" {
  type    = string
  default = "iac-3-on_prem_vpn_to_transit_vpc"
}
variable "tunnel1_psk" {
  type    = string
  default = "12345678"
}
variable "tunnel2_psk" {
  type    = string
  default = "87654321"
}
variable "tunnel1_inside_cidr" {
  type    = string
  default = "169.254.0.8/30"
}
variable "tunnel2_inside_cidr" {
  type    = string
  default = "169.254.0.12/30"
}

variable "cidr" {
    type = string
    default = "10.0.0.0/16"

}

variable "private_subnets" {
    type = list(string)
    default = ["10.0.0.0/24","10.0.1.0/24","10.0.2.0/24"]
}

variable "region" {
    type = string
    default = "ap-southeast-2"
}

variable "azs" {
    type = list(string)
    default = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]

}