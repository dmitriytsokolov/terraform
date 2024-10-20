resource "aws_ecs_cluster" "dev" {
  name = "dev"
}

resource "aws_iam_role" "ecs_node_role" {
  name               = "dev-ecs-node-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_node_doc.json
}

resource "aws_iam_role_policy_attachment" "ecs_node_role_policy" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_node" {
  name = "dev-ecs-node-profile"
  path = "/ecs/instance/"
  role = aws_iam_role.ecs_node_role.name
}

resource "aws_security_group" "ecs_node_sg" {
  name   = "dev-ecs-node-sg"
  vpc_id = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- ECS Launch Template ---

resource "aws_launch_template" "ecs_ec2_template" {
  name_prefix            = "dev-ecs-ec2-"
  image_id               = data.aws_ssm_parameter.ecs_node_ami.value
  instance_type          = "t3a.medium"
  vpc_security_group_ids = [aws_security_group.ecs_node_sg.id]

  iam_instance_profile { arn = aws_iam_instance_profile.ecs_node.arn }
  monitoring { enabled = true }

  user_data = base64encode(<<-EOF
      #!/bin/bash
      echo ECS_CLUSTER=${aws_ecs_cluster.dev.name} >> /etc/ecs/ecs.config;
    EOF
  )
}

resource "aws_autoscaling_group" "ecs" {
  depends_on                = [aws_subnet.public_subnet, aws_launch_template.ecs_ec2_template]
  name                      = "dev-ecs-asg"
  vpc_zone_identifier       = aws_subnet.public_subnet[*].id
  min_size                  = 1
  max_size                  = 5
  desired_capacity          = 2
  health_check_grace_period = 0
  health_check_type         = "EC2"
  force_delete              = true
  protect_from_scale_in     = false
  suspended_processes       = ["Terminate"]

  launch_template {
    id      = aws_launch_template.ecs_ec2_template.id
    version = "$Latest"
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }

  tag {
    key                 = "Name"
    value               = "dev-ecs-cluster"
    propagate_at_launch = true
  }

}

resource "aws_autoscaling_lifecycle_hook" "ecs" {
  name                   = "ecs-managed-draining-termination-hook"
  autoscaling_group_name = aws_autoscaling_group.ecs.name
  default_result         = "CONTINUE"
  heartbeat_timeout      = 30
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
}

# --- ECS Capacity Provider ---

resource "aws_ecs_capacity_provider" "dev" {
  name       = "dev-ecs-ec2"
  depends_on = [aws_autoscaling_group.ecs]

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "dev" {
  depends_on         = [aws_ecs_cluster.dev, aws_ecs_capacity_provider.dev]
  cluster_name       = aws_ecs_cluster.dev.name
  capacity_providers = [aws_ecs_capacity_provider.dev.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.dev.name
    base              = 1
    weight            = 100
  }
}

# --- ECS Task Role ---

resource "aws_iam_role" "ecs_task_role" {
  name               = "dev-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_doc.json
}

resource "aws_iam_role" "ecs_exec_role" {
  name               = "dev-ecs-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_doc.json
}

resource "aws_iam_role_policy_attachment" "ecs_exec_ecs_role_policy" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_exec_ssm_role_policy" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}
