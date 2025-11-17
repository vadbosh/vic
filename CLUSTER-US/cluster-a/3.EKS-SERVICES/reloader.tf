module "reloader_version" {
  source             = "./modules/helm-version"
  chart_name         = "reloader"
  versions_file_path = "${path.root}/helm_versions.json"
}


resource "helm_release" "reloader" {
  count      = module.reloader_version.version != null ? 1 : 0
  namespace  = "kube-system"
  name       = "stakater"
  repository = "https://stakater.github.io/stakater-charts"
  chart      = "reloader"
  version    = module.reloader_version.version
  values = [<<EOF
reloader:
  watchGlobally: true
  deployment:
    nodeSelector:  
      "eks-cluster/nodegroup": "${data.terraform_remote_state.eks_core.outputs.nodegroup_prefix}-metrics"
EOF
  ]
}

