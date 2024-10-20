

# resource "aws_kms_key" "kms" {
#   description = "example"
# }


# resource "aws_cloudwatch_log_group" "kafka" {
#   name = "kafka"
# }

# resource "aws_security_group" "kafka" {
#   name        = "kafka"
#   description = "Security group for kafka"
#   vpc_id      = aws_vpc.terracource_vpc.id
# }

# resource "aws_security_group_rule" "kafka_ingress" {
#   type              = "ingress"
#   from_port         = 0
#   to_port           = 65535
#   protocol          = "-1"
#   cidr_blocks       = var.access_ip
#   security_group_id = aws_security_group.kafka.id
# }

# resource "aws_security_group_rule" "kafka_egress" {
#   type              = "egress"
#   from_port         = 0
#   to_port           = 65535
#   protocol          = "-1"
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = aws_security_group.kafka.id
# }


# resource "aws_msk_cluster" "dev" {
#   cluster_name           = "dev"
#   kafka_version          = "3.7.x"
#   number_of_broker_nodes = length(local.azs)

#   client_authentication {
#     sasl {
#       iam = true
#     }
#   }

#   broker_node_group_info {
#     instance_type  = "kafka.t3.small"
#     client_subnets = aws_subnet.terracource_public_subnet[*].id
#     storage_info {
#       ebs_storage_info {
#         volume_size = 100
#       }
#     }
#     security_groups = [aws_security_group.kafka.id]
#     # connectivity_info {
#     #   public_access {
#     #     type = "SERVICE_PROVIDED_EIPS"
#     #   }
#     # }
#   }

#   encryption_info {
#     encryption_at_rest_kms_key_arn = aws_kms_key.kms.arn
#   }

#   open_monitoring {
#     prometheus {
#       jmx_exporter {
#         enabled_in_broker = true
#       }
#       node_exporter {
#         enabled_in_broker = true
#       }
#     }
#   }

#   logging_info {
#     broker_logs {
#       cloudwatch_logs {
#         enabled   = true
#         log_group = aws_cloudwatch_log_group.kafka.name
#       }
#     }
#   }

# }

# output "zookeeper_connect_string" {
#   value = aws_msk_cluster.dev.zookeeper_connect_string
# }

# output "bootstrap_brokers_tls" {
#   description = "TLS connection host:port pairs"
#   value       = aws_msk_cluster.dev.bootstrap_brokers_tls
# }

# output "bootstrap_brokers_sasl_iam" {
#   description = "bootstrap_brokers_sasl_iam"
#   value       = aws_msk_cluster.dev.bootstrap_brokers_sasl_iam
# }