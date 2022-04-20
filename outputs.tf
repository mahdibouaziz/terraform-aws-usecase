# To verify the selectrion of the right ami
output "aws_ami_id" {
  value = data.aws_ami.latest-amazon-linux-image.id
}

# To get the public ip of the ec2
output "ec2_public_ip" {
  value = aws_instance.myapp-server.public_ip
}
