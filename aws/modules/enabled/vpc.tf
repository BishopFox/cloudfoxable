resource "aws_vpc" "cloudfox" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  instance_tenancy     = "default"
  tags = {
    Name = "cloudfox"
  } 
}

resource "aws_internet_gateway" "cloudfox-igw" {
  vpc_id = aws_vpc.cloudfox.id
  tags = {
    Name = "cloudfox Internet Gateway"
  }
}

resource "aws_route_table" "cloudfox-public" {
  vpc_id = aws_vpc.cloudfox.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloudfox-igw.id
  }
  tags = {
    Name = "cloudfox Public Route Table"
  }
}

resource "aws_subnet" "cloudfox-operational-1" {
  vpc_id                  = aws_vpc.cloudfox.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = var.AWS_REGION_SUB_1
  tags = {
    Name = "cloudfox Operational Subnet 1"
  }
}

resource "aws_subnet" "cloudfox-operational-2" {
  vpc_id                  = aws_vpc.cloudfox.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = var.AWS_REGION_SUB_2
  tags = {
    Name = "cloudfox Operational Subnet 2"
  }
}

resource "aws_subnet" "cloudfox-operational-3" {
  vpc_id                  = aws_vpc.cloudfox.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = var.AWS_REGION_SUB_3
  tags = {
    Name = "cloudfox Operational Subnet 3"
  }
}

resource "aws_route_table_association" "cloudfox-operational-1" {
  subnet_id      = aws_subnet.cloudfox-operational-1.id
  route_table_id = aws_route_table.cloudfox-public.id
}

resource "aws_route_table_association" "cloudfox-operational-2" {
  subnet_id      = aws_subnet.cloudfox-operational-2.id
  route_table_id = aws_route_table.cloudfox-public.id
}

resource "aws_route_table_association" "cloudfox-operational-3" {
  subnet_id      = aws_subnet.cloudfox-operational-3.id
  route_table_id = aws_route_table.cloudfox-public.id
}




// output vpc_id
output "vpc_id" {
  value = aws_vpc.cloudfox.id
}

output "vpc_cidr" {
  value = aws_vpc.cloudfox.cidr_block
}

// output subnet_id
output "subnet1_id" {
  value = aws_subnet.cloudfox-operational-1.id
}

output "subnet2_id" {
  value = aws_subnet.cloudfox-operational-2.id
}

output "subnet3_id" {
  value = aws_subnet.cloudfox-operational-3.id
}