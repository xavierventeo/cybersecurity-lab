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
resource "aws_route_table" "lab_rt_public" {
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
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.lab_rt_public.id
}

# Create a private route table
resource "aws_route_table" "lab_rt_private" {
  vpc_id = aws_vpc.lab.id
  # Since this is going to be a private route table, 
  # we will not be adding a route
  tags = {
    Name = "Private Lab Route Table"
  }
}

resource "aws_route_table_association" "private_rt_association" {
  #  subnet_id      = aws_subnet.private_subnet_a
  route_table_id = aws_route_table.lab_rt_private.id
  count          = var.num_rds_private_subnets

  subnet_id = aws_subnet.private_subnet[count.index].id
}

# Subnets creation
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = var.subnet_cidr_block_public
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true # Enable automatic public IP assign
  tags = {
    Name = "Public Subnet"
  }
}

resource "aws_subnet" "firewall_subnet" {
  vpc_id            = aws_vpc.lab.id
  cidr_block        = var.subnet_cidr_block_firewall
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "Firewall Subnet"
  }
}

# RDS is deployed on private subnets and requiere 2 subnets in different availability zones
resource "aws_subnet" "private_subnet" {
  # count is the number of subnets needed for RDS 
  count             = 2
  vpc_id            = aws_vpc.lab.id
  cidr_block        = var.subnet_cidr_blocks_private[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "Private Subnet ${count.index}"
  }
}

# Create a db subnet group named "lab_database_subnet_group"
resource "aws_db_subnet_group" "database_subnet_group" {
  name        = "lab_database_subnet_group"
  description = "DB subnet group for the Lab"
  subnet_ids  = [for subnet in aws_subnet.private_subnet : subnet.id]
}

# SG for instances with public access
resource "aws_security_group" "web_app_instance_sg" {
  name        = "webapp-instance-security-group"
  description = "Security group for WebApp EC2 instance"
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

# SG for instances with public access
resource "aws_security_group" "public_instances_sg" {
  name        = "instance-security-group"
  description = "Security group for Public EC2 instance"
  vpc_id      = aws_vpc.lab.id

  # Inbound rule allows all traffic from allowed IP address
  ingress {
    from_port   = var.zero_port
    to_port     = var.zero_port
    protocol    = var.all_protocols
    cidr_blocks = [var.allowed_ip_address] # cidr_blocks expects a list of strings
  }

  # Outbound rule allows all outbound traffic
  egress {
    from_port = var.zero_port
    to_port   = var.zero_port
    protocol  = var.all_protocols

    cidr_blocks = [var.cidr_block_all_traffic]
  }
}

# SG for RDS
resource "aws_security_group" "database_sg" {
  name        = "rds-security-group"
  description = "Security group for RDS to EC2 instance"
  vpc_id      = aws_vpc.lab.id

  # Inbound rule allows HTTP traffic from Web App EC2 Instance
  ingress {
    from_port       = var.mysql_port
    to_port         = var.mysql_port
    protocol        = var.tcp_protocol
    security_groups = [aws_security_group.web_app_instance_sg.id]
  }
}
