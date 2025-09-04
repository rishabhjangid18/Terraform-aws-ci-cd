terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote backend (recommended for client projects)
  backend "s3" {
    bucket         = "my-terraform-states"   # <-- create this bucket manually
    key            = "ec2/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"       # <-- create this DynamoDB table manually
    encrypt        = true
  }
}

provider "aws" {
  region = "ap-south-1"
}

# 🔑 Key Pair
resource "aws_key_pair" "this" {
  key_name   = "terra-key-ec2"
  public_key = file("${path.module}/terra-key.pub")
}

# 🌐 Default VPC (safe for demo)
resource "aws_default_vpc" "default" {}

# 🔒 Security Group
resource "aws_security_group" "this" {
  name        = "terraform-sg"
  description = "Managed by Terraform"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "terraform-sg"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# 📦 Find Latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# 💻 EC2 Instance
resource "aws_instance" "this" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.this.key_name
  vpc_security_group_ids = [aws_security_group.this.id]

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }

  tags = {
    Name        = "Terraform-EC2"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
