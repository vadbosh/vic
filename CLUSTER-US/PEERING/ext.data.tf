
data "aws_vpcs" "net_workspace_acceptor_eks" {
  filter {
    name   = "tag:Name"
    values = ["${var.aws_vpc_acceptor}"]
  }
}

data "aws_vpcs" "net_workspace_requestor" {
  filter {
    name   = "tag:Name"
    values = ["${var.aws_vpc_requestor}"]
  }
}

data "aws_vpcs" "net_workspace_acceptor_eks_region" {
  provider = aws.sydney
  filter {
    name   = "tag:Name"
    values = ["${var.aws_vpc_acceptor}"]
  }
}

data "aws_vpcs" "net_workspace_requestor_region" {
  provider = aws.sydney
  filter {
    name   = "tag:Name"
    values = ["${var.aws_vpc_requestor}"]
  }
}
