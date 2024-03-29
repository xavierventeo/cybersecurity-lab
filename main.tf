# AWS provider configuration
provider "aws" {
  region = var.region
}

# EC2 instances creation
resource "aws_instance" "web_app_instance" {
  ami                    = var.ami_ubuntu
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_app_instance_sg.id]
  key_name               = var.ssh_key_name # Claves SSH
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


# Create Security Group rds-ec2-lab
# inbound rule del source del segurity group de la EC2
# Type MYSQL/Aurora	
# Protocol TCP
# Description Rule to allow connections from EC2 instances with sg-02ac5e5cb04049239 attached
# Port 3306
#

# Revie Security group ec2-reds-lab
# lo mismo pero con outbound rule
# Protocol TCP
*/

# TODO Create SG enabling TCP and SSH 
resource "aws_instance" "db_instance" {
  ami           = var.ami_amazon_linux
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private.id
  key_name      = var.ssh_key_name # Claves SSH
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
