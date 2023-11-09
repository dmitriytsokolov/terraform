resource "aws_vpc" "dev_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "dev_public_subnet_a" {
  vpc_id                  = aws_vpc.dev_vpc.id
  cidr_block              = "10.123.3.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-3a"

  tags = {
    Name = "dev-public-a"
  }
}

resource "aws_subnet" "dev_public_subnet_b" {
  vpc_id                  = aws_vpc.dev_vpc.id
  cidr_block              = "10.123.4.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-3b"

  tags = {
    Name = "dev-public-b"
  }
}

resource "aws_internet_gateway" "dev_internet_gateway" {
  vpc_id = aws_vpc.dev_vpc.id

  tags = {
    Name = "dev-igw"
  }
}

resource "aws_route_table" "dev_public_rt" {
  vpc_id = aws_vpc.dev_vpc.id

  tags = {
    Name = "dev_public_rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.dev_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.dev_internet_gateway.id
}

resource "aws_security_group" "dev_sg" {
  name        = "dev_sg"
  description = "dev security group"
  vpc_id      = aws_vpc.dev_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "dev_auth" {
  key_name   = "dev_key"
  public_key = file("id_ed25519.pub")
}

resource "aws_db_subnet_group" "dev_rds_subnet" {
  name       = "postgres"
  subnet_ids = [aws_subnet.dev_public_subnet_a.id, aws_subnet.dev_public_subnet_b.id]

  tags = {
    Name = "dev-postgres"
  }
}

resource "aws_db_instance" "dev_instance" {
  identifier             = "rds-terraform"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "15.3"
  username               = "devuser"
  password               = "devpassword"
  db_subnet_group_name   = aws_db_subnet_group.dev_rds_subnet.name
  vpc_security_group_ids = [aws_security_group.dev_sg.id]
  publicly_accessible    = true
  skip_final_snapshot    = true
}