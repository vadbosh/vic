resource "helm_release" "aws-load-balancer-controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  depends_on = [module.aws_lb_controller_pod_identity]
  values = [<<EOF
clusterName: "${var.cluster-name}"
replicaCount: 1
serviceAccount:
  create: false
  name: "${module.aws_lb_controller_pod_identity.associations.aws-lb-controller.service_account}"
nodeSelector: { "eks-cluster/nodegroup": "${var.cluster-name}-metrics", }
EOF
  ]
}

