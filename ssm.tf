# resource "random_password" "service_password" {
#   length  = 16
#   special = true
#   numeric = true
#   upper   = true
#   lower   = true
# }

resource "aws_ssm_parameter" "db_host" {
  name  = "db_host"
  type  = "String"
  value = aws_db_instance.dev_instance.address
}

resource "aws_ssm_parameter" "db_port" {
  name  = "db_port"
  type  = "String"
  value = aws_db_instance.dev_instance.port
}

resource "aws_ssm_parameter" "db_name" {
  name  = "db_name"
  type  = "String"
  value = aws_db_instance.dev_instance.db_name
}

resource "aws_ssm_parameter" "db_user" {
  name  = "db_user"
  type  = "String"
  value = postgresql_role.main.name
}

resource "aws_ssm_parameter" "db_password" {
  name  = "db_password"
  type  = "SecureString"
  value = postgresql_role.main.password
}

resource "aws_ssm_parameter" "keycloak_host" {
  name  = "keycloak_host"
  type  = "String"
  value = aws_instance.keycloak.public_dns
}
