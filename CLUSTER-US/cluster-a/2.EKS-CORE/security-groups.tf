
module "sg_main_internal" {
  source = "terraform-aws-modules/security-group/aws"
  #version = "~> 4"
  name        = "main-internal-${var.cluster-name}-sg"
  description = "main-internal-${var.cluster-name}-sg VPC security group"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id
  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "ssh2node-${var.cluster-name}"
      cidr_blocks = data.terraform_remote_state.network.outputs.cluster_top_cidr
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "http2node-${var.cluster-name}"
      cidr_blocks = data.terraform_remote_state.network.outputs.cluster_top_cidr
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "https2node-${var.cluster-name}"
      cidr_blocks = data.terraform_remote_state.network.outputs.cluster_top_cidr
    },
    {
      from_port   = 30000
      to_port     = 36000
      protocol    = "tcp"
      description = "nlb2node-health-${var.cluster-name}"
      cidr_blocks = data.terraform_remote_state.network.outputs.cluster_top_cidr
    }
  ]
  tags = {
    Environment = var.cluster-name
  }
}

module "sg_main_efs" {
  source = "terraform-aws-modules/security-group/aws"
  #version = "~> 4"
  name        = "efs2node-${var.cluster-name}"
  description = "efs2node-${var.cluster-name} VPC security group"
  #vpc_id      = join("", data.aws_vpcs.net_workspace.ids)
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
      description = "efs2node-${var.cluster-name} VPC"
      cidr_blocks = data.terraform_remote_state.network.outputs.cluster_top_cidr
    },
  ]
  tags = {
    Environment = var.cluster-name
  }
}

/*
module "sg_main_nlb" {
  source = "terraform-aws-modules/security-group/aws"
  #version = "~> 4"
  name        = "nlb-${var.cluster-name}"
  description = "nlb-${var.cluster-name} VPC security group"
  vpc_id      = join("", data.aws_vpcs.net_workspace.ids)
  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 6500
      protocol    = "tcp"
      description = "nlb-${var.cluster-name} VPC"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  tags = {
    Environment = "NLB ingress"
  }
}

module "sg_main_nlb" {
  source = "terraform-aws-modules/security-group/aws"
  #version = "~> 4"
  name        = "nlb-${var.cluster-name}"
  description = "nlb-${var.cluster-name} VPC security group"
  vpc_id      = join("", data.aws_vpcs.net_workspace.ids)
  # ingress
  ingress_with_source_security_group_id = [
    {
      rule                     = "alb-2-nlb"
      source_security_group_id = "sg-0e24eb90b07935701"
    },
  ]

  tags = {
    Environment = "NLB ingress"
  }
}
*/


