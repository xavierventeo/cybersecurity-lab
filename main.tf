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
