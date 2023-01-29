# Production VPC
resource "aws_vpc" "production-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Public subnets
resource "aws_subnet" "public-subnet-1" {
  cidr_block        = var.public_subnet_1_cidr
  vpc_id            = aws_vpc.production-vpc.id
  availability_zone = var.availability_zones[0]
}
resource "aws_subnet" "public-subnet-2" {
  cidr_block        = var.public_subnet_2_cidr
  vpc_id            = aws_vpc.production-vpc.id
  availability_zone = var.availability_zones[1]
}

# Private subnets
resource "aws_subnet" "private-subnet-1" {
  cidr_block        = var.private_subnet_1_cidr
  vpc_id            = aws_vpc.production-vpc.id
  availability_zone = var.availability_zones[0]
}
resource "aws_subnet" "private-subnet-2" {
  cidr_block        = var.private_subnet_2_cidr
  vpc_id            = aws_vpc.production-vpc.id
  availability_zone = var.availability_zones[1]
}

# Route tables for the subnets
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.production-vpc.id
}
resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.production-vpc.id
}

# Associate the newly created route tables to the subnets
resource "aws_route_table_association" "public-route-1-association" {
  route_table_id = aws_route_table.public-route-table.id
  subnet_id      = aws_subnet.public-subnet-1.id
}
resource "aws_route_table_association" "public-route-2-association" {
  route_table_id = aws_route_table.public-route-table.id
  subnet_id      = aws_subnet.public-subnet-2.id
}
resource "aws_route_table_association" "private-route-1-association" {
  route_table_id = aws_route_table.private-route-table.id
  subnet_id      = aws_subnet.private-subnet-1.id
}
resource "aws_route_table_association" "private-route-2-association" {
  route_table_id = aws_route_table.private-route-table.id
  subnet_id      = aws_subnet.private-subnet-2.id
}

# Elastic IP
# The private ip is the NAT machine's IP address that is 
# seen by the other machines in the subnet and also by the
# gateway interface machine. If this is not given then it is 
# hard to identify the NAT machine ...
# Note that this just creates an association between the gateway 
# machine and "some" fixed (10.0.0.5) machine. Downstream, we will
# see that the fixed machine is the NAT gateway machine
#
resource "aws_eip" "elastic-ip-for-nat-gw" {
  vpc                       = true
  associate_with_private_ip = "10.0.0.5"
  depends_on                = [aws_internet_gateway.production-igw]
}

# NAT gateway
# This resides in the public subnet and serves as one point of 
# connecting to internet for all EC2 instances that will reside
# in the private subnet. Further, NAT is typically used for one-way
# communication, from the private EC2 instances to outside world and not 
# the other way around (for security)
#
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.elastic-ip-for-nat-gw.id
  subnet_id     = aws_subnet.public-subnet-1.id
  depends_on    = [aws_eip.elastic-ip-for-nat-gw]
}

# since this NAT needs to act as proxy for all machines in 
# private subnet and that any traffic from the private subnet machine
# needs to go to NAT machine, we say:
# For all route-table "destinations" (0.0.0.0/0), i.e. for all machines 
# the route-table "target" is NAT gateway machine "aws_nat_gateway.nat-gw.id"
# which is assummed to know how to further the traffic from the machines
# This information about the NAT gateway machine being the "hub" is
# conveniently stored in the "private" subnet's route-table, so that *all* machines
# in the private subnets use NAT machine as the "target" to get to the outside
# world
#
resource "aws_route" "nat-gw-route" {
  # put in private subnet's route-table
  route_table_id         = aws_route_table.private-route-table.id
  # target in the route-table
  nat_gateway_id         = aws_nat_gateway.nat-gw.id
  # destination in the route-table
  destination_cidr_block = "0.0.0.0/0"
}

# Internet Gateway for the public subnet
resource "aws_internet_gateway" "production-igw" {
  vpc_id = aws_vpc.production-vpc.id
}

# Route the public subnet traffic through the Internet Gateway
resource "aws_route" "public-internet-igw-route" {
  route_table_id         = aws_route_table.public-route-table.id
  # table in the route-table (public subnet)
  gateway_id             = aws_internet_gateway.production-igw.id
  # destination in the route table (public subnet)
  destination_cidr_block = "0.0.0.0/0"
}




