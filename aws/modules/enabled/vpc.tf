data "aws_availability_zones" "available" {}

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

resource "aws_subnet" "cloudfox-operational" {
  count = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.cloudfox.id
  cidr_block              = cidrsubnet("10.0.0.0/16", 8, count.index)
  map_public_ip_on_launch = "true"
  availability_zone       = element(data.aws_availability_zones.available.names, count.index) 
  tags = {
    Name = "cloudfox Operational Subnet ${count.index}"
  }
}

resource "aws_route_table_association" "cloudfox-operational" {
  count = length(data.aws_availability_zones.available.names)
  subnet_id      = element(aws_subnet.cloudfox-operational.*.id, count.index)
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
output "subnet_id" {
  value = aws_subnet.cloudfox-operational.*.id
}
