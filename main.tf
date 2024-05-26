# AWS provider configuration
provider "aws" {
  region = var.region
}

# This data object is going to be
# holding all the available availability
# zones in our defined region
data "aws_availability_zones" "available" {
  state = var.aws_availability_zones
}

# EC2 instances creation
# EC2 Linux Web App creation
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

# EC2 Linux Mailserver creation
resource "aws_instance" "mailserver_instance" {
  ami                    = var.ami_amazon_linux
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.public_instances_sg.id]
  key_name               = var.ssh_key_name # Claves SSH
  tags = {
    Name = "Lab MailServer Instance"
  }
}

# EC2 Windows server creation
resource "aws_instance" "windowserver_instance" {
  ami                    = var.ami_windows_server_2016
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.public_instances_sg.id]
  key_name               = var.ssh_key_name # Claves SSH
  tags = {
    Name = "Lab WindowsServer Instance"
  }
}

# RDS Instance creation
resource "aws_db_instance" "db_instance" {
  identifier             = "labdatabase"
  allocated_storage      = var.database_settings.mysql.allocated_storage
  engine                 = var.database_settings.mysql.engine
  engine_version         = var.database_settings.mysql.engine_version
  instance_class         = var.database_settings.mysql.instance_class
  db_name                = var.database_settings.mysql.db_name
  username               = var.database_settings.mysql.username
  password               = var.database_settings.mysql.password
  multi_az               = var.database_settings.mysql.multi_az
  apply_immediately      = var.database_settings.mysql.apply_immediately
  skip_final_snapshot    = var.database_settings.mysql.skip_final_snapshot
  db_subnet_group_name   = aws_db_subnet_group.database_subnet_group.name
  vpc_security_group_ids = [aws_security_group.database_sg.id]
  tags = {
    Name = "Lab Database"
  }
}
