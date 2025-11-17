
data "aws_vpcs" "net_workspace_acceptor" {
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

