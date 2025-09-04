terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.3.0"
    }
  }
}

#key-pain
resource "aws_key_pair" "my_key" {
    key_name = "terra-key-ec2"
    public_key = file("terra-key.pub")
}

#vpc
resource "aws_default_vpc" "default" {
  
}

#security group
resource "aws_security_group" "mysggroup" {
    name = "terra-sg"
    description = "created with terrafrom"
    vpc_id = aws_default_vpc.default.id
    
    #inbound
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "ssh port"
    }

    ingress {
        to_port = 80
        from_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "http port"
    }

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "https port"
    }

    #outbound
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "all access open outbound"
    }

    tags = {
        Name = "automte-sg"
    }
}


#ec2 instance
resource "aws_instance" "terra-instance" {
      key_name = aws_key_pair.my_key.key_name
      security_groups = [aws_security_group.mysggroup.name]
      instance_type = "t2.micro"
      ami = "ami-0f918f7e67a3323f0"

      root_block_device {
        volume_size = 10
        volume_type = "gp3"
      }

      tags = {
        Name = "Terraform-created"
      }
}
