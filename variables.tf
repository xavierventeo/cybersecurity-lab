variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "cidr_block_all_traffic" {
  type    = string
  default = "0.0.0.0/0"
}

variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_cidr_block_protected" {
  type    = string
  default = "10.0.1.0/24"
}

variable "subnet_cidr_blocks_private" {
  description = "Available CIDR blocks for private subnets"
  type        = list(string)
  default = [
    "10.0.2.0/24",
    "10.0.3.0/24",
  ]
}

variable "num_rds_private_subnets" {
  type    = number
  default = 2
}

variable "subnet_cidr_block_firewall" {
  type    = string
  default = "10.0.4.0/24"
}

variable "tcp_protocol" {
  type    = string
  default = "tcp"
}

variable "ssh_protocol" {
  type    = string
  default = "ssh"
}

variable "all_protocols" {
  type    = string
  default = "-1"
}

variable "http_port" {
  description = "HTTP port"
  type        = number
  default     = 80
}

variable "ssh_port" {
  description = "SSH port"
  type        = number
  default     = 22
}

variable "mysql_port" {
  description = "MySQL port"
  type        = number
  default     = 3306
}

variable "zero_port" {
  description = "Port for allowed outbound traffic (default: 0)"
  default     = 0
}

variable "ephemeral_port_ini_for_external_ftp" {
  description = "Port for allowed public access to FTP"
  default     = 1025
}

variable "ephemeral_port_final_for_external_ftp" {
  description = "Port for allowed public access to FTP"
  default     = 1029
}

variable "allowed_ip_address" {
  description = "Allowed IP address for SSH access"
  type        = string
  default     = "0.0.0.0/0" # All traffic by default
}

variable "ami_amazon_linux" {
  type    = string
  default = "ami-074254c177d57d640"
}

variable "ami_ubuntu" {
  type    = string
  default = "ami-0c1c30571d2dae5c9"
}

variable "ami_windows_server_2016" {
  type    = string
  default = "ami-0d9799c654b4dcb1d"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "ssh_key_name" {
  type    = string
  default = "lab_key_pair"
}

variable "ssh_key_full_name" {
  type    = string
  default = "~/.ssh/lab_key_pair.pem"
}

variable "ubuntu_user" {
  type    = string
  default = "ubuntu"
}

variable "aws_availability_zones" {
  type    = string
  default = "available"
}

variable "database_settings" {
  description = "Database configuration settings"
  type        = map(any)
  default = {
    "mysql" = {
      allocated_storage   = 10
      engine              = "mysql"
      engine_version      = "5.7"
      instance_class      = "db.t3.micro"
      db_name             = "labdatabase"
      username            = "admin"
      password            = "password" #Change by a proper value at terraform.tfvars
      multi_az            = false
      apply_immediately   = true
      skip_final_snapshot = true
    }
  }
}

variable "db_parameter_group_family" {
  description = "DB parameter group family"
  type        = string
  default     = "mysql5.7"
}

variable "db_option_group_engine_name" {
  description = "Engine name for the RDS DB option group"
  type        = string
  default     = "mysql"
}

variable "db_option_group_engine_version" {
  description = "Major engine version for the RDS DB option group"
  type        = string
  default     = "5.7"
}

variable "db_option_group_description" {
  description = "Description of the RDS DB option group"
  type        = string
  default     = "Option group for enabling MariaDB audit plugin"
}

variable "mariadb_audit_plugin_events" {
  description = "Events to be logged by the MariaDB audit plugin"
  type        = string
  default     = "CONNECT,QUERY,QUERY_DDL,QUERY_DML,QUERY_DML_NO_SELECT,QUERY_DCL"
}
