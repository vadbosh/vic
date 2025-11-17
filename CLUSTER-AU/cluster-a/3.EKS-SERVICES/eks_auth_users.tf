data "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
}

module "eks-aws-auth" {
  source                    = "terraform-aws-modules/eks/aws//modules/aws-auth"
  version                   = "~> 20.0"
  manage_aws_auth_configmap = true
  create_aws_auth_configmap = false
  aws_auth_accounts         = try(yamldecode(data.kubernetes_config_map.aws_auth.data.mapAccounts), [])
  aws_auth_roles            = try(yamldecode(data.kubernetes_config_map.aws_auth.data.mapRoles), [])
  /*
  aws_auth_roles = distinct(concat(
    try(yamldecode(data.kubernetes_config_map.aws_auth.data.mapRoles), []),
    [
      {
        rolearn  = "arn:aws:iam::381142409470:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AWSAdministratorAccess_2f0885e508cc7257"
        username = "arn:aws:sts::381142409470:assumed-role/AWSReservedSSO_AWSAdministratorAccess_2f0885e508cc7257/vadym.bashayev-wellnessliving.com"
        groups   = ["system:masters"]
      }
    ]
  ))
  */
  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::${data.terraform_remote_state.eks_core.outputs.aws_account_id}:user/sergey.lebedev"
      username = "sergey.lebedev"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::${data.terraform_remote_state.eks_core.outputs.aws_account_id}:role/thoth-compile-production-au"
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:masters"]
    }
  ]
}
