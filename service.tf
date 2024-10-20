resource "postgresql_role" "main" {
  depends_on     = [aws_db_instance.dev_instance]
  name           = "main"
  password       = "mainpass"
  login          = true
  skip_drop_role = true
}

resource "postgresql_schema" "main" {
  depends_on   = [aws_db_instance.dev_instance, postgresql_role.main]
  name         = "main"
  owner        = "main"
  drop_cascade = true
}

resource "postgresql_grant" "main" {
  depends_on  = [aws_db_instance.dev_instance, postgresql_schema.main]
  database    = aws_db_instance.dev_instance.db_name
  role        = postgresql_role.main.name
  schema      = postgresql_schema.main.name
  object_type = "schema"
  privileges  = ["CREATE", "USAGE"]
}
