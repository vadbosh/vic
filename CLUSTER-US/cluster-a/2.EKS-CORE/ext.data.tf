
data "aws_caller_identity" "current" {}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "tf.k8s.state"
    key    = var.s3_key_vpc_data
    region = "us-east-1"
  }
}

