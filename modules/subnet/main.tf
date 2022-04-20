# Create a subnet for this vpc
resource "aws_subnet" "myapp-subnet-1" {
  vpc_id     = var.vpc_id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name = "${var.env_prefix}-subnet-1"
  }
}

# Create an internet gateway to assign it to the routetable 
resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = var.vpc_id

  tags = {
     Name = "${var.env_prefix}-igw"
  }
}

# Associate the default route table (main) and added it a new route
resource "aws_default_route_table" "main-rtb" {
    default_route_table_id = var.default_route_table_id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }

    tags = {
        Name = "${var.env_prefix}-main-rtb"
    }
}


# # Create a new route table with 2 rules (for local and internet )
# resource "aws_route_table" "myapp-route-table" {
#     vpc_id = var.vpc_id
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

