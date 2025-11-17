
data "aws_vpcs" "net_workspace" {
  filter {
    name   = "tag:Name"
    values = ["${var.aws_vpcs_tag_name}"]
  }
}

data "aws_nat_gateways" "ngws" {
  vpc_id = join("", data.aws_vpcs.net_workspace.ids)
}

data "aws_internet_gateway" "igtws" {
  filter {
    name   = "tag:Name"
    values = ["${var.aws_internet_gateway_tag_name}"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

