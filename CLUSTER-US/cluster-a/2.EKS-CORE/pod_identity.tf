
module "cluster_autoscaler_pod_identity" {
  source                           = "terraform-aws-modules/eks-pod-identity/aws"
  name                             = "cluster-autoscaler"
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = ["${var.cluster-name}"]
  association_defaults = {
    namespace       = "kube-system"
    service_account = "cluster-autoscaler"
  }
  associations = {
    cluster-autoscaler = {
      cluster_name = var.cluster-name
    }
  }
  tags = {
    Environment = var.cluster-name
  }
  depends_on = [module.eks]
}

module "aws_ebs_csi_pod_identity" {
  source                    = "terraform-aws-modules/eks-pod-identity/aws"
  name                      = "aws-ebs-csi"
  attach_aws_ebs_csi_policy = true
  association_defaults = {
    namespace       = "kube-system"
    service_account = "ebs-csi-controller-sa"
  }
  associations = {
    cluster-ebs = {
      cluster_name = var.cluster-name
    }
  }
  tags = {
    Environment = var.cluster-name
  }
  depends_on = [module.eks]
}

module "aws_efs_csi_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"
  name   = "aws-efs-csi"
  #version                   = "1.7.0"
  attach_aws_efs_csi_policy = true
  association_defaults = {
    namespace       = "kube-system"
    service_account = "efs-csi-controller-sa"
  }
  associations = {
    cluster-efs = {
      cluster_name = var.cluster-name
    }
  }
  tags = {
    Environment = var.cluster-name
  }
  depends_on = [module.eks]
}

/*
module "aws_lb_controller_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"
  name   = "aws-lbc"
  #version                         = "1.7.0"
  attach_aws_lb_controller_policy = true
  association_defaults = {
    namespace       = "kube-system"
    service_account = "aws-load-balancer"
  }
  associations = {
    aws-lb-controller = {
      cluster_name = var.cluster-name
    }
  }
  tags = {
    Environment = "all"
  }
  depends_on = [module.eks]
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

output "asse" {
  value = module.aws_lb_controller_pod_identity.associations.aws-lb-controller.service_account
}


module "aws_cloudwatch_observability_pod_identity" {
  source                                     = "terraform-aws-modules/eks-pod-identity/aws"
  name                                       = "aws-cloudwatch-observability"
  attach_aws_cloudwatch_observability_policy = true
  association_defaults = {
    namespace       = "keda"
    service_account = "keda-operator"
  }
  associations = {
    aws-cloudwatch = {
      cluster_name = var.cluster-name
    }
  }

  tags = {
    Environment = "all"
  }
  depends_on = [module.eks]
}
*/
