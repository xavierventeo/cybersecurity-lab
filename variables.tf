variable "allowed_ip_address" {
  description = "Allowed IP address for SSH access"
  type        = string
  default     = "0.0.0.0/0" # All traffic by default
}
