provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "myvpc"
    Environemnt = "dev"
  }
}

data "aws_availability_zones" "zone" {
}

#Subnets CIDR

locals {
  public_subnets_cidrs = ["10.0.1.0/24"]
  private_subnets_cidrs = ["10.0.101.0/24"]
}

#Public Subnets

resource "aws_subnet" "public_subnets" {
  count = length(local.public_subnets_cidrs)
  vpc_id = aws_vpc.vpc.id
  cidr_block = local.public_subnets_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.zone.names[count.index]
  tags = {
    Name = "public-subnet-${count.index+1}"
    Environemnt = "dev"
  }

}

resource "aws_subnet" "private_subnets" {
  count = length(local.private_subnets_cidrs)
  vpc_id = aws_vpc.vpc.id
  cidr_block = local.private_subnets_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.zone.names[count.index]
  tags = {
    Name = "private-subnet-${count.index+1}"
    Environemnt = "dev"
  }
  }

  resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id
    count = length(local.public_subnets_cidrs)
     tags = {
    Name = "igw-${count.index+1}"
    Environemnt = "dev"
  }
  }

  resource "aws_eip" "nat_ips" {
    count = length(local.public_subnets_cidrs)
    domain = "vpc"
    tags = {
     Name = "eip-${count.index+1}"
     Environemnt = "dev"
  }
  }

  resource "aws_nat_gateway" "nat" {
    count = length(local.public_subnets_cidrs)
    allocation_id = aws_eip.nat_ips[count.index].id
    subnet_id = aws_subnet.public_subnets[count.index].id
    depends_on = [aws_internet_gateway.igw]
    tags = {
     Name = "ngw-${count.index+1}"
     Environemnt = "dev"
  }
  }

  resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.vpc.id
    count = length(local.public_subnets_cidrs)
    route {
     cidr_block = "0.0.0.0/0"
     gateway_id = aws_internet_gateway.igw[count.index].id
     }
    tags = {
     Name = "public-rt-${count.index+1}"
     Environemnt = "dev"
  }
  }

  resource "aws_route_table" "private_rt" {
    vpc_id = aws_vpc.vpc.id
    count = length(local.private_subnets_cidrs)
    route {
     cidr_block = "0.0.0.0/0"
     nat_gateway_id = aws_nat_gateway.nat[count.index].id
     }
    tags = {
     Name = "public-rt-${count.index+1}"
     Environemnt = "dev"
  }
  }

  resource "aws_route_table_association" "public_ass" {
    count = length(local.public_subnets_cidrs)
    subnet_id = aws_subnet.public_subnets[count.index].id
    route_table_id = aws_route_table.public_rt[count.index].id
  }

  resource "aws_route_table_association" "private_ass" {
    count = length(local.private_subnets_cidrs)
    subnet_id = aws_subnet.private_subnets[count.index].id
    route_table_id = aws_route_table.private_rt[count.index].id
  }
