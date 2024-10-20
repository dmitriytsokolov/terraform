variable "region" {
  type = string
}

variable "project_name" {
  type = string
}

variable "master_bucket_name" {
  type = string
}

variable "git_ssh_url" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.111.0.0/16"
}

variable "access_ip" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "keycloak_instance_type" {
  type    = string
  default = "t3a.medium"
}

variable "jenkins_instance_type" {
  type    = string
  default = "t3a.medium"
}

variable "main_volume_size" {
  type    = number
  default = 20
}

variable "default_key_path" {
  type    = string
  default = "public.key"
}

variable "default_key_name" {
  type    = string
  default = "master-key"
}