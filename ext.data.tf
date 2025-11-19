data "aws_eks_cluster" "eks_cluster" {
  name = data.terraform_remote_state.eks_core.outputs.cluster-name
}

data "aws_caller_identity" "current" {}

data "terraform_remote_state" "eks_core" {
  backend = "s3"
  config = {
    bucket = "tf.k8s.state"
    key    = var.s3_key_eks_data
    region = "us-east-1"
  }
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "tf.k8s.state"
    key    = var.s3_key_vpc_data
    region = "us-east-1"
  }
}

