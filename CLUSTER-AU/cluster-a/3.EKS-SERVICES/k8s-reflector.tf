module "reflector_version" {
  source             = "./modules/helm-version"
  chart_name         = "reflector"
  versions_file_path = "${path.root}/helm_versions.json"
}

resource "helm_release" "reflector" {
  count      = module.reflector_version.version != null ? 1 : 0
  namespace  = "kube-system"
  name       = "reflector"
  repository = "https://emberstack.github.io/helm-charts"
  chart      = "reflector"
  version    = module.reflector_version.version
  values = [<<EOF
nodeSelector:
  "eks-cluster/nodegroup": "${data.terraform_remote_state.eks_core.outputs.nodegroup_prefix}-metrics" 
EOF
  ]
}
