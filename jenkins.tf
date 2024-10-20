resource "aws_iam_policy" "jenkins" {
  name = "jenkins"

  policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ecr:*",
                "sts:*",
                "ssm:*",
                "s3:*"
            ],
            "Resource": "*"
        }
    ]
}
EOT
}

resource "aws_iam_role" "jenkins" {
  name = "jenkins"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "jenkins" {
  name       = "jenkins"
  policy_arn = aws_iam_policy.jenkins.arn
  roles      = [aws_iam_role.jenkins.name]
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "jenkins"
  role = aws_iam_role.jenkins.name
}

resource "aws_instance" "jenkins" {
  instance_type          = var.jenkins_instance_type
  ami                    = data.aws_ami.ami.id
  iam_instance_profile   = aws_iam_instance_profile.jenkins.name
  key_name               = aws_key_pair.master.key_name
  vpc_security_group_ids = [aws_security_group.public_sg.id]
  subnet_id              = aws_subnet.public_subnet[0].id

  root_block_device {
    volume_size = var.main_volume_size
  }

  tags = {
    Name = "jenkins"
  }

  provisioner "local-exec" {
    command = "aws ec2 wait instance-status-ok --instance-ids ${self.id} --region ${var.region}"
  }
}

resource "null_resource" "jenkins_install" {
  depends_on = [aws_instance.jenkins]
  provisioner "local-exec" {
    command = "ansible-playbook -i ${aws_instance.jenkins.public_ip}, playbook/jenkins/jenkins.yml -e \"region=${var.region} master_bucket_name=${var.master_bucket_name} git_ssh_url=${var.git_ssh_url}\""
  }
}