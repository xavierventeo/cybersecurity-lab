# EC2 instances creation
# EC2 Linux Web App creation
resource "aws_instance" "web_app_instance" {
  ami                    = var.ami_ubuntu
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.protected_subnet.id
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
  subnet_id              = aws_subnet.protected_subnet.id
  vpc_security_group_ids = [aws_security_group.protected_instances_sg.id]
  key_name               = var.ssh_key_name # Claves SSH
  tags = {
    Name = "Lab MailServer Instance"
  }
}

# EC2 Windows server creation
resource "aws_instance" "windowserver_instance" {
  ami                    = var.ami_windows_server_2016
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.protected_subnet.id
  vpc_security_group_ids = [aws_security_group.protected_instances_sg.id]
  key_name               = var.ssh_key_name # Claves SSH
  tags = {
    Name = "Lab WindowsServer Instance"
  }
}
