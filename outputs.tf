
# To get the public ip of the ec2
output "ec2_public_ip" {
  value = module.myapp-webserver.ec2_public_ip
}
