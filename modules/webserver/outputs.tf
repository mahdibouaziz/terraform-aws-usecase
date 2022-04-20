
# To get the public ip of the ec2
output "ec2_public_ip" {
    value = aws_instance.myapp-server.public_ip
}
