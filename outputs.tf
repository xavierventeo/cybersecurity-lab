# Outputs for EC2 Instances created
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
