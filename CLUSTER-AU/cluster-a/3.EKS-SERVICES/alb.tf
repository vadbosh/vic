module "aws_load_balancer_controller_version" {
  source             = "./modules/helm-version"
  chart_name         = "aws-load-balancer-controller"
  versions_file_path = "${path.root}/helm_versions.json"
}

resource "helm_release" "aws-load-balancer-controller" {
  count      = module.aws_load_balancer_controller_version.version != null ? 1 : 0
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  depends_on = [module.aws_lb_controller_pod_identity]
  version    = module.aws_load_balancer_controller_version.version
  values = [<<EOF
clusterName: "${data.terraform_remote_state.eks_core.outputs.cluster-name}"
replicaCount: 1
serviceAccount:
  create: false
  name: "${module.aws_lb_controller_pod_identity.associations.aws-lb-controller.service_account}"
nodeSelector: { "eks-cluster/nodegroup": "${data.terraform_remote_state.eks_core.outputs.nodegroup_prefix}-metrics", }
vpcId: "${data.terraform_remote_state.network.outputs.vpc_id}"
EOF
  ]
}

