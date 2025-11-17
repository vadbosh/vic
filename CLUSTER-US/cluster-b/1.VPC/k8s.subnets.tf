
resource "aws_vpc_ipv4_cidr_block_association" "cluster_sandbox_cidr" {
  count      = var.cidr_create ? 1 : 0
  vpc_id     = join("", data.aws_vpcs.net_workspace.ids)
  cidr_block = var.k8s_cidr_block_associations
}

module "subnets" {
  source                                = "cloudposse/dynamic-subnets/aws"
  name                                  = format("%s-%s", var.cluster-name, "${random_string.suffix.result}")
  vpc_id                                = join("", data.aws_vpcs.net_workspace.ids)
  igw_id                                = ["${data.aws_internet_gateway.igtws.id}"]
  ipv4_cidr_block                       = [var.k8s_cidr_block_associations]
  public_route_table_per_subnet_enabled = false
  availability_zones                    = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  max_nats                              = var.max_nats
  max_subnet_count                      = length([data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]])
  ipv6_enabled                          = false
  nat_gateway_enabled                   = true
  private_route_table_enabled           = true

  public_subnets_additional_tags = {
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
    "Peering"                                   = "YES"
  }

  private_subnets_additional_tags = {
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
    "Peering"                                   = "YES"
  }
  depends_on = [aws_vpc_ipv4_cidr_block_association.cluster_sandbox_cidr]
}
