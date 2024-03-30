# Outputs for EC2 Instances created
output "web_app_instance_public_ip_and_name" {
  value = {
    ip  = aws_instance.web_app_instance.public_ip
    tag = aws_instance.web_app_instance.tags.Name
  }
  description = "Web App instance and public IP"
}

output "database_endpoint" {
  description = "The endpoint of the database"
  value       = aws_db_instance.db_instance.address
}

// This will output the database port
output "database_port" {
  description = "The port of the database"
  value       = aws_db_instance.db_instance.port
}