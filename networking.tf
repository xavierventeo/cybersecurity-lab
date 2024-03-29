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

  # Inbound rule allows SSH traffic from allowed IP address
  ingress {
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = var.tcp_protocol         # protocol expects a simple string
    cidr_blocks = [var.allowed_ip_address] # cidr_blocks expects a list of strings
  }

  # Inbound rule allows HTTP traffic from allowed IP address
  ingress {
    from_port   = var.http_port
    to_port     = var.http_port
    protocol    = var.tcp_protocol
    cidr_blocks = [var.allowed_ip_address]
  }

  # Outbound rule allows all outbound traffic
  egress {
    from_port = var.zero_port
    to_port   = var.zero_port
    protocol  = var.all_protocols

    cidr_blocks = [var.cidr_block_all_traffic]
  }
}
/*
# SG for WebApp instance to allow acces to RDS
resource "aws_security_group" "webapp_ec2_rds_sg" {
  name        = "instance-security-group"
  description = "Security group for EC2 to RDS"
  vpc_id      = aws_vpc.lab.id

  # Outbound rule allows HTTP traffic from allowed IP address
  egress {
    from_port   = var.mysql_port
    to_port     = var.mysql_port
    protocol    = var.tcp_protocol
    security_groups = [aws_security_group.rds_webapp_ec2_sg.id]
  }
}
*/
# SG for RDS
resource "aws_security_group" "rds_webapp_ec2_sg" {
  name        = "rds-security-group"
  description = "Security group for RDS to EC2 instance"
  vpc_id      = aws_vpc.lab.id

  # Inbound rule allows HTTP traffic from allowed IP address
  ingress {
    from_port   = var.mysql_port
    to_port     = var.mysql_port
    protocol    = var.tcp_protocol
    security_groups = [aws_security_group.web_app_instance_sg.id]
  #  cidr_blocks = ["${aws_security_group.webapp_ec2_rds_sg.id}"]
  }
}
