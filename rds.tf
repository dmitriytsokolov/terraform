resource "aws_db_subnet_group" "dev_rds_subnet" {
  name       = "postgres"
  subnet_ids = aws_subnet.public_subnet[*].id

  tags = {
    Name = "dev-postgres"
  }
}

resource "aws_security_group" "dev_sg" {
  name        = "dev_sg"
  description = "dev security group"
  vpc_id      = aws_vpc.vpc.id

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

resource "aws_db_instance" "dev_instance" {
  depends_on             = [aws_internet_gateway.ig]
  identifier             = "dev-instance"
  instance_class         = "db.t3.micro"
  db_name                = "dev"
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "16"
  username               = "devuser"
  password               = "devpassword"
  db_subnet_group_name   = aws_db_subnet_group.dev_rds_subnet.name
  vpc_security_group_ids = [aws_security_group.dev_sg.id]
  publicly_accessible    = true
  skip_final_snapshot    = true

  tags = {
    Name = "dev"
  }
}
