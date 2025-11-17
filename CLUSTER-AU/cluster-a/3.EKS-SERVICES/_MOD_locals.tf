
locals {
  cluster_letter = {
    letter = "a"
  }
  cluster_env = {
    expected_region       = data.terraform_remote_state.network.outputs.region
    expected_env          = "thoth-production"
    expected_main_backend = "eks-services-${local.cluster_letter.letter}"
    expected_eks          = "eks-core-${local.cluster_letter.letter}"
    expected_vpc          = "vpc-${local.cluster_letter.letter}"
  }
  ingress_keys = {
    external_nginx        = "${var.ingress_external_config.helm_release_name}-${data.terraform_remote_state.eks_core.outputs.cluster-name}"
    external_nginx_shared = "${var.ingress_external_shared_config.helm_release_name}-${data.terraform_remote_state.eks_core.outputs.cluster-name}"
  }
  ingress_security_group_ids = {
    external_nginx        = data.terraform_remote_state.network.outputs.security_group_id_map[local.ingress_keys.external_nginx]
    external_nginx_shared = data.terraform_remote_state.network.outputs.security_group_id_map[local.ingress_keys.external_nginx_shared]
  }
  ingress_2lb_name = {
    internal_nginx        = "${data.terraform_remote_state.eks_core.outputs.cluster-name}-internal"
    external_nginx        = "${data.terraform_remote_state.eks_core.outputs.cluster-name}-au-wl"
    external_nginx_shared = "${data.terraform_remote_state.eks_core.outputs.cluster-name}-external"
    external_2_ssh        = "${data.terraform_remote_state.eks_core.outputs.cluster-name}-extn-2-ssh"
    #external_2_ssh        = format("%s-%s", substr(data.terraform_remote_state.eks_core.outputs.cluster-name, 0, 10), "external-2-ssh")
  }
  ingress_controller = {
    internal_nginx        = "${var.ingress_internal_config.class_name}-nginx"
    external_nginx        = "ingress-${var.ingress_external_config.class_name}"
    external_nginx_shared = "ingress-${var.ingress_external_shared_config.class_name}"
  }
  ingress_nodegroup = {
    ingress = "${data.terraform_remote_state.eks_core.outputs.nodegroup_prefix}-ingress"
  }
  default_proxy_url = {
    ingress = "thoth.downpage.au.wellnessliving.com"
  }
}

