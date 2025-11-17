data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "tf.k8s.state"
    key    = var.s3_key_vpc_data
    region = "us-east-1"
  }
}

data "aws_security_group" "selected" {
  name = var.security_group_name
}

