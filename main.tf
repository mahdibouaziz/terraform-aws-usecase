terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-west-3"
}

# Create our variables
variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}
variable "avail_zone" {}
variable "env_prefix" {}
variable "instance_type" {}

# Create a vpc
resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}

# Create a subnet for this vpc
resource "aws_subnet" "myapp-subnet-1" {
  vpc_id     = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name = "${var.env_prefix}-subnet-1"
  }
}

# Create an internet gateway to assign it to the routetable 
resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id

  tags = {
     Name = "${var.env_prefix}-igw"
  }
}

# # Create a new route table with 2 rules (for local and internet )
# resource "aws_route_table" "myapp-route-table" {
#     vpc_id = aws_vpc.myapp-vpc.id
#     route {
#         cidr_block = "0.0.0.0/0"
#         gateway_id = aws_internet_gateway.myapp-igw.id
#     }

#     tags = {
#         Name = "${var.env_prefix}-rtb"
#     }
# }


# # Associate the subnet to the route table created
# resource "aws_route_table_association" "a" {
#   subnet_id      = aws_subnet.myapp-subnet-1.id
#   route_table_id = aws_route_table.myapp-route-table.id
# }

# Associate the default route table (main) and added it a new route
resource "aws_default_route_table" "main-rtb" {
    default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }

    tags = {
        Name = "${var.env_prefix}-main-rtb"
    }
}

# Configure firewall rules for our ec2 instance (default security groups)
# SSH (port 22) and  nginx (port 8080) 
resource "aws_default_security_group" "myapp-default-sg" {
#   name        = "myapp-default-sg"
  vpc_id      = aws_vpc.myapp-vpc.id

  # For incoming requests (inbound)
  ingress {
      description      = "SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"] # WHO IS ALLOWED TO SSH TO THIS Ec2
  }

    ingress {
      description      = "nginx"
      from_port        = 8080
      to_port          = 8080
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"] # any ip adress can access 
  }

  # for outcoming (outbound)
  egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      prefix_list_ids = []
  }

  tags = {
    Name = "${var.env_prefix}-myapp-sg"
  }
}


# Get the AMI dynamically with filter
data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners = ["137112412989"] # Canonical

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"]
  }
}

# To verify the selectrion of the right ami
output "aws_ami_id" {
  value = data.aws_ami.latest-amazon-linux-image.id
}

# Create the EC2 instance
resource "aws_instance" "myapp-server" {
  #required
  ami           = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type

  #optional
  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [ aws_default_security_group.myapp-default-sg.id ]
  availability_zone = var.avail_zone

  associate_public_ip_address = true

  key_name = "mahdi-key"

  tags = {
    Name = "${var.env_prefix}-myapp-ec2"
  }
}