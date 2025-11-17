
module "vpc_peering" {
  source                                    = "cloudposse/vpc-peering/aws"
  name                                      = format("%s>%s", var.aws_vpc_requestor, var.aws_vpc_acceptor)
  auto_accept                               = true
  requestor_allow_remote_vpc_dns_resolution = true
  acceptor_allow_remote_vpc_dns_resolution  = true
  requestor_vpc_id                          = join("", data.aws_vpcs.net_workspace_requestor.ids)
  acceptor_vpc_id                           = join("", data.aws_vpcs.net_workspace_acceptor.ids)

  requestor_route_table_tags = {
    Name = "${var.aws_vpc_requestor}"
  }
  acceptor_route_table_tags = {
    "Peering" = "YES"
  }

  tags = {
    "Name" = format("%s>%s", var.aws_vpc_requestor, var.aws_vpc_acceptor)
  }
  #acceptor_ignore_cidrs = ["10.20.0.0/16", "10.21.0.0/16", "10.23.0.0/16", "10.24.0.0/16", "10.25.0.0/16", "10.26.0.0/16", "10.27.0.0/16"]
}
