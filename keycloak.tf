resource "postgresql_role" "keycloak" {
  depends_on     = [aws_db_instance.dev_instance]
  name           = "keycloak"
  password       = "keycloakpass"
  login          = true
  skip_drop_role = true
}

resource "postgresql_schema" "keycloak" {
  depends_on   = [aws_db_instance.dev_instance, postgresql_role.keycloak]
  name         = "keycloak"
  owner        = "keycloak"
  drop_cascade = true
}

resource "postgresql_grant" "keycloak" {
  depends_on  = [aws_db_instance.dev_instance, postgresql_schema.keycloak]
  database    = aws_db_instance.dev_instance.db_name
  role        = postgresql_role.keycloak.name
  schema      = postgresql_schema.keycloak.name
  object_type = "schema"
  privileges  = ["CREATE", "USAGE"]
}

resource "aws_instance" "keycloak" {
  instance_type          = var.keycloak_instance_type
  ami                    = data.aws_ami.ami.id
  key_name               = aws_key_pair.master.key_name
  vpc_security_group_ids = [aws_security_group.public_sg.id]
  subnet_id              = aws_subnet.public_subnet[0].id

  root_block_device {
    volume_size = var.main_volume_size
  }

  tags = {
    Name = "keycloak"
  }

  provisioner "local-exec" {
    command = "aws ec2 wait instance-status-ok --instance-ids ${self.id} --region ${var.region}"
  }
}

resource "null_resource" "keycloak_certificate" {
  provisioner "local-exec" {
    command = "ansible-playbook --connection=local playbook/cert.yml -e \"region=${var.region} bucket_name=${var.master_bucket_name}\""
  }
}

resource "null_resource" "keycloak_install" {
  depends_on = [aws_instance.keycloak, null_resource.keycloak_certificate]
  provisioner "local-exec" {
    command = "ansible-playbook -i ${aws_instance.keycloak.public_ip}, playbook/keycloak/keycloak.yml -e \"keycloak_quarkus_host=${aws_instance.keycloak.public_dns} db_host=${aws_db_instance.dev_instance.address} db_name=${aws_db_instance.dev_instance.db_name}\""
  }
}
