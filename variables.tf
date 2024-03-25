variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "availability_zone" {
  type    = string
  default = "eu-west-1a"
}

variable "cidr_block_all_traffic" {
  type    = string
  default = "0.0.0.0/0"
}

variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_cidr_block_public" {
  type    = string
  default = "10.0.1.0/24"
}

variable "subnet_cidr_block_private" {
  type    = string
  default = "10.0.2.0/24"
}

variable "subnet_cidr_block_firewall" {
  type    = string
  default = "10.0.3.0/24"
}

variable "tcp_protocol" {
  type    = string
  default = "tcp"
}

variable "all_protocols" {
  type    = string
  default = "-1"
}

variable "allowed_ip_address" {
  description = "Allowed IP address for SSH access"
  type        = string
  default     = "0.0.0.0/0" # All traffic by default
}

variable "ami" {
  type    = string
  default = "ami-074254c177d57d640"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "key_name" {
  type    = string
  default = "lab_key_pair"
}
