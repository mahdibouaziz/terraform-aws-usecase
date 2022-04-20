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


# Create a key pair for this instance
resource "aws_key_pair" "ssh-key" {
  key_name   = "myapp-key"
  public_key = file(var.public_key_location)
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

  key_name = aws_key_pair.ssh-key.key_name

  tags = {
    Name = "${var.env_prefix}-myapp-ec2"
  }

  # Execute commands on EC2 server on the time of the creation
  # this is a multiline script
  #Note: this will only be executed once on the initial run
  user_data = file("entry-script.sh")

  #####    Provisioner is not recomanded by the terraform team       #####
  # # Prepare the connection
  # connection {
  #   type     = "ssh"
  #   host     = self.public_ip
  #   user     = "ec2-user"
  #   private_key = file(var.private_key_location)
  # }

  # # Copy the file from local machine to the remote
  # provisioner "file" {
  #   source = "entry-script.sh"
  #   destination = "/home/ec2-user/entry-script.sh"
  # }

  # # Execute commands remotly on the server (if you specify a file it must exists in the server)
  # provisioner "remote-exec" {
  #   # inline = [
  #   #   "mkdir testdir"
  #   # ]
  #   script = file("entry-script.sh") #this script must exists in the remote machine
  # }

  # # execute commands locally (on my local machine) after a resource is created
  # provisioner "local-exec" {
  #     command = "echo ${self.public_ip}"
  # }

}

