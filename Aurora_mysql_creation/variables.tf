locals {
  common_tags = {
    Name = "Aurora_mysql"
  }
}

variable "region" {
  default = ""
}
variable "profile" {
  default = ""
}
variable "vpc_cidr_block" {
  default = ""
}
variable "privateSub1_cidr_block" {
  default = ""
}
variable "privateSub2_cidr_block" {
  default = ""
}
variable "publicSub1_cidr_block" {
  default = ""
}
variable "publicSub2_cidr_block" {
  default = ""
}
variable "cluster_identifier" {
  default = ""
}
variable "database_name" {
  default = ""
}
variable "master_username" {
  default = ""
}
variable "master_password" {
  default = ""
}
variable "instance_class" {
  default = ""
}