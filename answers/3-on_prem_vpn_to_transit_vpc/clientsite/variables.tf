variable "aws_access_key_id" {}
variable "aws_secret_access_key" {}
variable "exercise_name" {
  type    = string
  default = "iac-3-clientsite"
}

variable "cidr" {
  type    = string
  default = "192.168.0.0/16"

}

variable "private_subnets" {
  type    = list(string)
  default = ["192.168.0.0/24", "192.168.1.0/24", "192.168.2.0/24"]
}

variable "region" {
  type    = string
  default = "ap-southeast-2"
}

variable "azs" {
  type    = list(string)
  default = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]

}

variable "cloudsite_cidr" {
  type = string
  default = "10.0.0.0/16"
}

variable "ssh_keyname" {
  type = string
  default = "chris-syd"
}