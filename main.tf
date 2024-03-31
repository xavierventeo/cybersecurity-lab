# AWS provider configuration
provider "aws" {
  region = var.region
}

// This data object is going to be
// holding all the available availability
// zones in our defined region
data "aws_availability_zones" "available" {
  state = "available"
}

# EC2 instances creation
resource "aws_instance" "web_app_instance" {
  ami                    = var.ami_ubuntu
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_app_instance_sg.id]
  key_name               = var.ssh_key_name # Claves SSH
  tags = {
    Name = "Lab WebAppServer Instance"
  }
}

# RDS Instance creation
resource "aws_db_instance" "db_instance" {
  identifier             = "labdatabase"
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  db_name                = "labdatabase"
  username               = "admin"
  password               = "password"
  multi_az               = false
  apply_immediately      = true
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.database_subnet_group.name
  vpc_security_group_ids = [aws_security_group.database_sg.id]
  tags = {
    Name = "labdatabase"
  }
}

/*
resource "aws_instance" "db_instance" {
  ami           = var.ami_amazon_linux
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private.id
  key_name      = var.ssh_key_name # Claves SSH
  tags = {
    Name = "DBInstance"
  }
}
*/
