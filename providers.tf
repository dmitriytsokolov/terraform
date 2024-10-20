terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.47"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.22.0"
    }
  }
}

provider "aws" {
  region                   = var.region
  shared_credentials_files = ["./credentials"]
  profile                  = "default"
}

provider "postgresql" {
  host            = aws_db_instance.dev_instance.address
  port            = aws_db_instance.dev_instance.port
  database        = aws_db_instance.dev_instance.db_name
  username        = aws_db_instance.dev_instance.username
  password        = aws_db_instance.dev_instance.password
  max_connections = 500
  connect_timeout = 500
  superuser       = false
}