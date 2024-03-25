# AWS provider configuration
provider "aws" {
  region = var.region
}

# VPC creation
resource "aws_vpc" "lab" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "VPC lab"
  }
}

# Internet Gateway (IGW) creation
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.lab.id

  tags = {
    Name = "VPC IG Lab"
  }
}

# Route table to able flow connectivity throw Internet on public subnets
resource "aws_route_table" "lab_rtb-public" {
  vpc_id = aws_vpc.lab.id

  route {
    cidr_block = var.cidr_block_all_traffic
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Public Lab Route Table"
  }
}

# Associate route table to public subnet
resource "aws_route_table_association" "public_subnet_asso" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.lab_rtb-public.id
}

# Subnets creation
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = var.subnet_cidr_block_public
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true # Enable automatic public IP assign
  tags = {
    Name = "Public Subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.lab.id
  cidr_block        = var.subnet_cidr_block_private
  availability_zone = var.availability_zone
  tags = {
    Name = "Private Subnet"
  }
}

resource "aws_subnet" "firewall" {
  vpc_id            = aws_vpc.lab.id
  cidr_block        = var.subnet_cidr_block_firewall
  availability_zone = var.availability_zone
  tags = {
    Name = "firewall"
  }
}

# SG for instances with public access
resource "aws_security_group" "web_app_instance_sg" {
  name        = "instance-security-group"
  description = "Security group for EC2 instance"
  vpc_id      = aws_vpc.lab.id

  # Regla de entrada para permitir el tráfico SSH desde la dirección IP permitida
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = var.tcp_protocol         #protocol expects a simple string
    cidr_blocks = [var.allowed_ip_address] #cidr_blocks expects a list of strings
  }

  # Regla de entrada para permitir el tráfico HTTP desde la dirección IP permitida
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = var.tcp_protocol
    cidr_blocks = [var.allowed_ip_address]
  }

  # Regla de salida para permitir todo el tráfico saliente
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = var.all_protocols
    cidr_blocks = [var.cidr_block_all_traffic]
  }
}

# EC2 instances creation
resource "aws_instance" "web_app_instance" {
  ami                    = var.ami # AMI de Amazon Linux
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_app_instance_sg.id]
  key_name               = var.key_name # Claves SSH
  tags = {
    Name = "WebAppInstance"
  }
}

/*
resource "aws_db_subnet_group" "db_private_subnet_group" {
  name       = "rds-dvwa"
  subnet_ids = aws_subnet.private.id

  tags = {
    Name = "RDS DVWA"
  }
}

# RDS Instance creation
resource "aws_db_instance" "db_instance" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  db_subnet_group_name   = aws_db_subnet_group.db_private_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds.id]
}
*/

# TODO Create SG enabling TCP and SSH 
resource "aws_instance" "db_instance" {
  ami           = var.ami # AMI de Amazon Linux
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private.id
  key_name      = var.key_name # Claves SSH
  tags = {
    Name = "DBInstance"
  }
}

/*
# AWS Network Firewall to control traffic between the web application on the public subnet and the database on the private subnet

# Firewall stateful rule group to allow traffic for the database
resource "aws_networkfirewall_rule_group" "stateful_rule_allow_db" {
  type     = "STATEFUL"
  name     = "AllowWebToDBTraffic"
  capacity = 100

  rule_group {
    rule_variables {
      ip_sets {
        key = "WEBAPP_INSTANCE"
        ip_set {
          definition = ["10.0.1.0/24"]
        }
      }
      ip_sets {
        key = "DB_INSTANCE"
        ip_set {
          definition = ["10.0.2.0/24"]
        }
      }
      port_sets {
        key = "DB_PORTS"
        port_set {
          definition = ["3306", "443", "80"]
        }
      }
    }
    rules_source {
      stateful_rule {
        action = "PASS"
        header {
          destination      = "$WEBAPP_INSTANCE"
          destination_port = "$DB_PORTS"
          protocol         = "TCP"
          direction        = "FORWARD"
          source_port      = "ANY"
          source           = "$DB_INSTANCE"
        }
        rule_option {
          keyword = "sid:1"
        }
      }
    }
  }
}

# Firewall policy creation attaching the previous rules group
resource "aws_networkfirewall_firewall_policy" "internal_firewall_policy" {
  name        = "InternalFirewallPolicy"
  description = "Policy for the internal network firewall"

  firewall_policy {
    stateless_default_actions          = ["aws:drop"]
    stateless_fragment_default_actions = ["aws:drop"]
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.stateful_rule_allow_db.arn
    }
  }
}

# AWS Network Firewall creation attached to the VPC and firewall subnet. Previous policy attached
resource "aws_networkfirewall_firewall" "internal_firewall" {
  name                = "InternalFirewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.internal_firewall_policy.arn
  vpc_id              = aws_vpc.lab.id

  subnet_mapping {
    subnet_id = aws_subnet.firewall.id
  }
}

output "firewall_name" {
  value = {
    name = aws_networkfirewall_firewall.internal_firewall.name
  }
  description = "AWS Network firewall"
}
*/

# Created resources outputs
output "web_app_instance_public_ip_and_name" {
  value = {
    ip  = aws_instance.web_app_instance.public_ip
    tag = aws_instance.web_app_instance.tags.Name
  }
  description = "Web App instance and public IP"
}

output "db_instance_private_ip_and_name" {
  value = {
    ip  = aws_instance.db_instance.private_ip
    tag = aws_instance.db_instance.tags.Name
  }
  description = "DataBase instance and private IP"
}
