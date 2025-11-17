# --- us:production-eks <=> au:production-eks ---
module "vpc_peering_eks_2_eks" {
  source                        = "cloudposse/vpc-peering-multi-account/aws"
  name                          = format("%s>%s", "production-eks-us-east-1", "production-eks-ap-southeast-2")
  requester_aws_assume_role_arn = ""
  requester_region              = "us-east-1"
  requester_vpc_id              = join("", data.aws_vpcs.net_workspace_acceptor_eks.ids)
  requester_vpc_tags = {
    Name = "${var.aws_vpc_acceptor}"
  }
  requester_allow_remote_vpc_dns_resolution = true
  accepter_enabled                          = true
  auto_accept                               = true
  accepter_aws_assume_role_arn              = ""
  accepter_region                           = "ap-southeast-2"
  accepter_vpc_id                           = join("", data.aws_vpcs.net_workspace_acceptor_eks_region.ids)
  accepter_vpc_tags = {
    Name = "${var.aws_vpc_acceptor}"
  }
  accepter_allow_remote_vpc_dns_resolution = true
  tags = {
    "Name" = format("%s>%s", "production-eks-us-east-1", "production-eks-ap-southeast-2")
  }
}

# --- us:production <=> au:production-eks ---
module "vpc_peering_prod_2_eks" {
  source                        = "cloudposse/vpc-peering-multi-account/aws"
  name                          = format("%s>%s", "production-us-east-1", "production-eks-ap-southeast-2")
  requester_aws_assume_role_arn = ""
  requester_region              = "ap-southeast-2"
  requester_vpc_id              = join("", data.aws_vpcs.net_workspace_acceptor_eks_region.ids)
  requester_vpc_tags = {
    Name = "${var.aws_vpc_acceptor}"
  }
  requester_allow_remote_vpc_dns_resolution = true
  accepter_enabled                          = true
  auto_accept                               = true
  accepter_aws_assume_role_arn              = ""
  accepter_region                           = "us-east-1"
  accepter_vpc_id                           = join("", data.aws_vpcs.net_workspace_requestor.ids)
  accepter_vpc_tags = {
    Name = "${var.aws_vpc_requestor}"
  }
  accepter_allow_remote_vpc_dns_resolution = true
  tags = {
    "Name" = format("%s>%s", "production-us-east-1", "production-eks-ap-southeast-2")
  }
}

# --- us:production-eks <=> au:production ---
module "vpc_peering_us-eks_2_au-prod" {
  source                        = "cloudposse/vpc-peering-multi-account/aws"
  name                          = format("%s>%s", "production-eks-us-east-1", "production-ap-southeast-2")
  requester_aws_assume_role_arn = ""
  requester_region              = "us-east-1"
  requester_vpc_id              = join("", data.aws_vpcs.net_workspace_acceptor_eks.ids)
  requester_vpc_tags = {
    Name = "${var.aws_vpc_acceptor}"
  }
  requester_allow_remote_vpc_dns_resolution = true
  accepter_enabled                          = true
  auto_accept                               = true
  accepter_aws_assume_role_arn              = ""
  accepter_region                           = "ap-southeast-2"
  accepter_vpc_id                           = join("", data.aws_vpcs.net_workspace_requestor_region.ids)
  accepter_vpc_tags = {
    Name = "${var.aws_vpc_requestor}"
  }
  accepter_allow_remote_vpc_dns_resolution = true
  tags = {
    "Name" = format("%s>%s", "production-eks-us-east-1", "production-ap-southeast-2")
  }
}

