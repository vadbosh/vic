
module "aws_lb_controller_pod_identity" {
  source                          = "terraform-aws-modules/eks-pod-identity/aws"
  name                            = "aws-lbc"
  attach_aws_lb_controller_policy = true
  association_defaults = {
    namespace       = "kube-system"
    service_account = "aws-load-balancer"
  }
  associations = {
    aws-lb-controller = {
      cluster_name = data.terraform_remote_state.eks_core.outputs.cluster-name
    }
  }
  tags = {
    Environment = "all"
  }
}

resource "kubernetes_service_account" "alb_sa" {
  metadata {
    name      = module.aws_lb_controller_pod_identity.associations.aws-lb-controller.service_account
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.aws_lb_controller_pod_identity.iam_role_arn
    }
  }
  depends_on = [module.aws_lb_controller_pod_identity]
}

output "aws-lb-controller_service_account" {
  value = module.aws_lb_controller_pod_identity.associations.aws-lb-controller.service_account
}

