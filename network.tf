locals {
  azs = data.aws_availability_zones.available.names
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "dev"
  }
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "dev"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "dev"
  }
}

resource "aws_route" "route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
}

resource "aws_default_route_table" "route_table" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "public_subnet" {
  count                   = length(local.azs)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone       = local.azs[count.index]

  tags = {
    Name = "dev-public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnet" {
  count                   = length(local.azs)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, length(local.azs) + count.index)
  map_public_ip_on_launch = false
  availability_zone       = local.azs[count.index]

  tags = {
    Name = "dev-private-subnet-${count.index + 1}"
  }
}

resource "aws_route_table_association" "public_association" {
  count          = length(local.azs)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_security_group" "public_sg" {
  name        = "dev_public_sg"
  description = "Security group for public instances"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_security_group_rule" "ingress_all" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = var.access_ip
  security_group_id = aws_security_group.public_sg.id
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.public_sg.id
}
