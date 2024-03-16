# Configuración del proveedor AWS
provider "aws" {
  region = "eu-west-1" # Cambia la región según tu preferencia
}

# Creación de la VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Creación de subredes
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
}

resource "aws_subnet" "firewall" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
}

# Creación de instancias
resource "aws_instance" "web_app_instance" {
  ami           = "ami-074254c177d57d640" # AMI de Amazon Linux
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
  #key_name      = "lab_key_pair" # Claves SSH
  tags = {
    Name = "WebAppInstance"
  }
}

resource "aws_instance" "db_instance" {
  ami           = "ami-074254c177d57d640" # AMI de Amazon Linux
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private.id
  #key_name      = "lab_key_pair" # Claves SSH
  tags = {
    Name = "DBInstance"
  }
}

# Creación de una política de firewall para el Network Firewall
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

# Creación del firewall de red para el tráfico entre las subredes pública y privada
resource "aws_networkfirewall_firewall" "internal_firewall" {
  name                = "InternalFirewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.internal_firewall_policy.arn
  vpc_id              = aws_vpc.main.id

  subnet_mapping {
    subnet_id = aws_subnet.firewall.id
  }

}

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
