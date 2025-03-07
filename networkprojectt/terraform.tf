
terraform{

    required_providers {
        aws = {
        source  = "hashicorp/aws"
        version = "~> 5.87.0"
        }
  }

  required_version = ">= 1.10.5"
}

provider "aws" {
  region     = "eu-west-1"
  access_key = "AKIAYRH5NFP6GKWWOE7P"  # Your AWS Access Key
  secret_key = "gj3r/xAHOhTnuzdYBuVJSbsGnGET6FEoQwikfhPB"  # Your AWS Secret Key
}

# VPC
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "default_vpc"
  }
}

# Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "my_internet_gateway"
  }
}

# Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public_route_table"
  }
}

# Route Table Association
resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group
resource "aws_security_group" "http_access" {
  name        = "http_access"
  description = "Security group for HTTP and SSH access"
  vpc_id      = aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Replace with your own IP address or range
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Open to the world, if you need public HTTP access
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Key Pair (use the correct public key file, make sure the file ends with .pub)
resource "aws_key_pair" "my_key" {
  key_name   = "my_pub_key"
  public_key = file("C:/networkprojectt/.ssh/my_pub_key.pub")  # Make sure it's the public key file
}

# EC2 Instance
resource "aws_instance" "example_server" {
  ami                    = "ami-0e063207e92b63437"  # Replace with a valid AMI ID for the region
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.http_access.id]
  subnet_id              = aws_subnet.public.id
  key_name               = aws_key_pair.my_key.key_name

  tags = {
    Name = "Test_Server"
  }
}

# Outputs
output "vpc_id" {
  value = aws_vpc.default.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "security_group_id" {
  value = aws_security_group.http_access.id
}

output "key_name" {
  value = aws_key_pair.my_key.key_name
}

output "instance_id" {
  value = aws_instance.example_server.id
}

