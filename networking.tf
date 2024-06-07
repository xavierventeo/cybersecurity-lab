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

###################################
#vpc_cidr_block "10.0.0.0/16"
#cidr_block_all_traffic  "0.0.0.0/0"
#subnet_cidr_block_public "10.0.1.0/24"
#subnet_cidr_blocks_private
#    "10.0.2.0/24",
#    "10.0.3.0/24",
#subnet_cidr_block_firewall "10.0.4.0/24"


# Route tables block: First it have to get the firewall endpoint
data "aws_vpc_endpoint" "lab_firewall_endpoint" {
  vpc_id = aws_vpc.lab.id

  tags = {
    "AWSNetworkFirewallManaged" = "true"
    "Firewall"                  = aws_networkfirewall_firewall.lab_firewall.arn
  }

  depends_on = [aws_networkfirewall_firewall.lab_firewall]
}

# Route table Internet Gateway
# Routes traffic that's destined for the public subnet to the firewall subnet. 
# The customer subnet shows the private IP address range behind the publicly assigned address. 
# The subnet has public addresses assigned, which are either auto-generated or assigned via Elastic IP address. 
# Within a VPC, only private IP addresses are used for communication.

resource "aws_route_table" "lab_rt_internet_gateway" {
  vpc_id = aws_vpc.lab.id

  route {
    cidr_block      = var.subnet_cidr_block_public
    vpc_endpoint_id = data.aws_vpc_endpoint.lab_firewall_endpoint.id
  }

  tags = {
    Name = "Internet Gateway Lab Route Table"
  }
}

# Requieres explicit edge association
resource "aws_route_table_association" "public_subnet_association" {
  gateway_id     = aws_internet_gateway.gw.id
  route_table_id = aws_route_table.lab_rt_internet_gateway.id
}

# Route table Firewall to able flow connectivity throw Internet on public subnets
# Routes traffic that's destined for anywhere inside the Lab VPC  to the local address. 
# Routes traffic that's destined for anywhere else (0.0.0.0/0) to the internet gateway.
resource "aws_route_table" "lab_rt_firewall" {
  vpc_id = aws_vpc.lab.id

  route {
    cidr_block = var.cidr_block_all_traffic
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Firewall Lab Route Table"
  }
}

# Associate route table to firewall subnet
resource "aws_route_table_association" "firewall_subnet_association" {
  subnet_id      = aws_subnet.firewall_subnet.id
  route_table_id = aws_route_table.lab_rt_firewall.id
}

# Route table to able flow connectivity throw Internet on public subnets
# Routes traffic that's destined for anywhere inside the Lab VPC to the local address. 
# Routes traffic that's destined for anywhere else (0.0.0.0/0) to the firewall subnet.
# Before the firewall inclusion, the customer subnet route table routed the 0.0.0.0/0 traffic to Internet Gateway.
resource "aws_route_table" "lab_rt_protected" {
  vpc_id = aws_vpc.lab.id

  route {
    cidr_block      = var.cidr_block_all_traffic
    vpc_endpoint_id = data.aws_vpc_endpoint.lab_firewall_endpoint.id
  }

  tags = {
    Name = "Protected Lab Route Table"
  }
}

# Associate route table to public subnet
resource "aws_route_table_association" "protected_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.lab_rt_protected.id
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
  route_table_id = aws_route_table.lab_rt_private.id
  count          = var.num_rds_private_subnets

  subnet_id = aws_subnet.private_subnet[count.index].id
}

##################################

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
