# Outputs for EC2 Instances created
output "web_app_instance_public_ip_and_name" {
  value = {
    ip  = aws_instance.web_app_instance.public_ip
    tag = aws_instance.web_app_instance.tags.Name
  }
  description = "Web App instance and public IP"
}

# Outputs for RDS Database created
output "database_endpoint" {
  description = "The endpoint of the database"
  value       = aws_db_instance.db_instance.address
}

output "database_port" {
  description = "The port of the database"
  value       = aws_db_instance.db_instance.port
}

# Outputs for Firewall created
output "firewall_name" {
  value = {
    name = aws_networkfirewall_firewall.lab_firewall.name
  }
  description = "AWS Network firewall"
}
