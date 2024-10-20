resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/dev"
  retention_in_days = 1
}

resource "aws_ecs_task_definition" "spring_archetype" {
  depends_on         = [aws_ecr_repository.app]
  family             = "spring-archetype"
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_exec_role.arn
  network_mode       = "awsvpc"
  cpu                = 256
  memory             = 256

  container_definitions = jsonencode([{
    name         = "spring_archetype",
    image        = "${aws_ecr_repository.app.repository_url}:latest",
    essential    = true,
    portMappings = [{ containerPort = 8080, hostPort = 8080 }],

    "environment" = [
      {
        name  = "KEYCLOAK_SCHEME"
        value = "https"
      }
    ],
    "secrets" : [
      {
        "name" : "DB_HOST",
        "valueFrom" : "${aws_ssm_parameter.db_host.arn}"
      },
      {
        "name" : "DB_PORT",
        "valueFrom" : "${aws_ssm_parameter.db_port.arn}"
      },
      {
        "name" : "DB_NAME",
        "valueFrom" : "${aws_ssm_parameter.db_name.arn}"
      },
      {
        "name" : "DB_USER",
        "valueFrom" : "${aws_ssm_parameter.db_user.arn}"
      },
      {
        "name" : "DB_PASSWORD",
        "valueFrom" : "${aws_ssm_parameter.db_password.arn}"
      },
      {
        "name" : "KEYCLOAK_HOST",
        "valueFrom" : "${aws_ssm_parameter.keycloak_host.arn}"
      }
    ],

    logConfiguration = {
      logDriver = "awslogs",
      options = {
        "awslogs-region"        = "${var.region}",
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name,
        "awslogs-stream-prefix" = "app"
      }
    },
  }])
}

resource "aws_security_group" "ecs_task" {
  depends_on  = [aws_vpc.vpc]
  name_prefix = "dev-ecs-task-sg-"
  description = "Allow all traffic within the VPC"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "spring_archetype" {
  depends_on      = [aws_ecs_cluster.dev, aws_security_group.ecs_task, aws_subnet.public_subnet, aws_lb_target_group.spring_archetype, aws_ecs_capacity_provider.dev]
  name            = "spring-archetype"
  cluster         = aws_ecs_cluster.dev.id
  task_definition = aws_ecs_task_definition.spring_archetype.arn
  desired_count   = 1

  network_configuration {
    security_groups = [aws_security_group.ecs_task.id]
    subnets         = aws_subnet.public_subnet[*].id
  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.dev.name
    base              = 1
    weight            = 100
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.spring_archetype.arn
    container_name   = "spring_archetype"
    container_port   = 8080
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOF
    echo "Update service desired count to 0 before destroy."
    REGION=${split(":", self.cluster)[3]}
    aws ecs update-service --region $REGION --cluster ${self.cluster} --service ${self.name} --desired-count 0 --force-new-deployment
    echo "Update service command executed successfully."
    EOF
  }

  timeouts {
    delete = "5m"
  }
}

resource "aws_security_group" "http" {
  depends_on  = [aws_vpc.vpc]
  name_prefix = "http-sg-"
  description = "Allow all HTTP/HTTPS traffic from public"
  vpc_id      = aws_vpc.vpc.id

  dynamic "ingress" {
    for_each = [80, 443]
    content {
      protocol    = "tcp"
      from_port   = ingress.value
      to_port     = ingress.value
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "spring_archetype" {
  depends_on         = [aws_subnet.public_subnet]
  name               = "spring-archetype"
  load_balancer_type = "application"
  subnets            = aws_subnet.public_subnet[*].id
  security_groups    = [aws_security_group.http.id]
}

resource "aws_lb_target_group" "spring_archetype" {
  depends_on  = [aws_vpc.vpc]
  name        = "spring-archetype"
  vpc_id      = aws_vpc.vpc.id
  protocol    = "HTTP"
  port        = 8080
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/spring-archetype/health"
    port                = 8080
    matcher             = 200
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http" {
  depends_on        = [aws_lb_target_group.spring_archetype, aws_lb.spring_archetype]
  load_balancer_arn = aws_lb.spring_archetype.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.spring_archetype.id
  }
}
