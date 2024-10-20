resource "aws_key_pair" "master" {
  key_name   = var.default_key_name
  public_key = file(var.default_key_path)
}
