# AWS provider configuration
provider "aws" {
  region = "eu-west-1" # Europe (Ireland)
}

# VPC creation
resource "aws_vpc" "lab" {
  cidr_block = "10.0.0.0/16"
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
resource "aws_route_table" "second_rt" {
  vpc_id = aws_vpc.lab.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "2nd Route Table"
  }
}

# Associate route table to public subnet
resource "aws_route_table_association" "public_subnet_asso" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.second_rt.id
}

# Subnets creation
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = true # Enable automatic public IP assign
  tags = {
    Name = "Public Subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.lab.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-1b"
  tags = {
    Name = "Private Subnet"
  }
}

resource "aws_subnet" "firewall" {
  vpc_id     = aws_vpc.lab.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "eu-west-1b"
  tags = {
    Name = "firewall"
  }
}

# EC2 instances creation
resource "aws_instance" "web_app_instance" {
  ami           = "ami-074254c177d57d640" # AMI de Amazon Linux
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
  key_name      = "lab_key_pair" # Claves SSH
  tags = {
    Name = "WebAppInstance"
  }
}

resource "aws_instance" "db_instance" {
  ami           = "ami-074254c177d57d640" # AMI de Amazon Linux
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private.id
  key_name      = "lab_key_pair" # Claves SSH
  tags = {
    Name = "DBInstance"
  }
}

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

output "firewall_name" {
  value = {
    name = aws_networkfirewall_firewall.internal_firewall.name
  }
  description = "AWS Network firewall"
}