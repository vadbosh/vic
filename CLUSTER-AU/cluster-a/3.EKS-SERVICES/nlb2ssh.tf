# NLB for SSH
resource "aws_lb" "ssh_nlb" {
  name                             = local.ingress_2lb_name.external_2_ssh
  internal                         = false #  true IF internal
  load_balancer_type               = "network"
  subnets                          = data.terraform_remote_state.network.outputs.public_subnet_ids
  security_groups                  = ["${local.ingress_security_group_ids.external_nginx_shared}"]
  enable_cross_zone_load_balancing = true
  ip_address_type                  = "ipv4"

  tags = {
    Environment = "${data.terraform_remote_state.eks_core.outputs.cluster-name}"
    ManagedBy   = "Terraform-Connector"
    Name        = local.ingress_2lb_name.external_2_ssh
  }
}
