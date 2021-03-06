
# Configure firewall rules for our ec2 instance (default security groups)
# SSH (port 22) and  nginx (port 8080) 
resource "aws_default_security_group" "myapp-default-sg" {
  vpc_id      = var.vpc_id

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
    values = [var.image_name]
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
  # to import the value from the module
  subnet_id = var.subnet_id
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

