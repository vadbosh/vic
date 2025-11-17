
module "metrics_server_version" {
  source             = "./modules/helm-version"
  chart_name         = "metrics-server"
  versions_file_path = "${path.root}/helm_versions.json"
}

resource "helm_release" "metrics-server" {
  count      = module.metrics_server_version.version != null ? 1 : 0
  namespace  = "kube-system"
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = module.metrics_server_version.version
  values = [<<EOF
nodeSelector: { "eks-cluster/nodegroup": "${data.terraform_remote_state.eks_core.outputs.nodegroup_prefix}-metrics", }
updateStrategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1
podDisruptionBudget:
  enabled: true
  minAvailable: 1
replicas: "2"
metrics:
  enabled: true
serviceMonitor:
  enabled: false # !!!
  additionalLabels:
    release: monitoring
  interval: 1m
  scrapeTimeout: 10s
resources:
  requests:
    cpu: 100m
    memory: 200Mi
EOF
  ]
}

