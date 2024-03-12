provider "aws" {
  region = "eu-west-1"
}

##### Configuración de red #####

# Recurso para la VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16" # Rango de direcciones IP de tu VPC
}

# Recurso para la subred pública
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24" # Rango de direcciones IP de tu subred pública
  map_public_ip_on_launch = true          # Habilita asignación automática de IP pública
}

# Recurso para la subred privada de Linux
resource "aws_subnet" "private_subnet_linux" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24" # Rango de direcciones IP de tu subred privada para Linux
}

# Recurso para la subred privada de Windows
resource "aws_subnet" "private_subnet_windows" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24" # Rango de direcciones IP de tu subred privada para Windows
}

##### Creación de instancias EC2 #####

# Recurso para el Firewall (pfSense)
resource "aws_instance" "firewall" {
  ami           = "ami-0fc3317b37c1269d3" # AMI for Firewall PfSense. AMI Amazon Linux and install pfSense to avoid pfSense AMI costs
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "FirewallServerInstance"
  }
}

# Recurso para las instancias de Linux
resource "aws_instance" "linux_instance" {
  ami           = "ami-0fc3317b37c1269d3" # AMI de Amazon Linux
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet_linux.id

  tags = {
    Name = "LinuxServerInstance"
  }
}

# Recurso para las instancias de Windows
resource "aws_instance" "windows_instance" {
  ami           = "ami-0a6e6f76c99f6999f" # AMI de Windows Server 2016
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet_windows.id

  tags = {
    Name = "WindowsServerInstance"
  }
}

# Bloque output para mostrar información sobre los recursos creados
output "firewall_public_ip" {
  value       = aws_instance.firewall.public_ip
  description = "Dirección IP pública del Firewall"
}

output "linux_instance_ip_and_tag" {
  value = {
    ip  = aws_instance.linux_instance.private_ip
    tag = aws_instance.linux_instance.tags.Name
  }
  description = "Dirección IP privada y tag de la instancia Linux"
}

output "windows_instance_ip_and_tag" {
  value = {
    ip  = aws_instance.windows_instance.private_ip
    tag = aws_instance.windows_instance.tags.Name
  }
  description = "Dirección IP privada y tag de la instancia Windows"
}