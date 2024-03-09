provider "aws" {
  region = "eu-west-1"
}

resource "aws_instance" "test_server" {
  ami           = "ami-0fc3317b37c1269d3"
  instance_type = "t2.micro"

  tags = {
    Name = "ExampleTestServerInstance"
  }
}
