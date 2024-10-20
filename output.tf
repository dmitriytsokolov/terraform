output "service-alb" {
  value = "http://${aws_lb.spring_archetype.dns_name}"
}

output "jenkins-url" {
  value = "http://${aws_instance.jenkins.public_dns}:8080"
}

output "keycloak-url" {
  value = "https://${aws_instance.keycloak.public_dns}"
}

output "db-address" {
  value = "${aws_db_instance.dev_instance.address}"
}
