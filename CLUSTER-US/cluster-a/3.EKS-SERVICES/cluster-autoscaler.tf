module "cluster_autoscaler_version" {
  source             = "./modules/helm-version"
  chart_name         = "cluster-autoscaler"
  versions_file_path = "${path.root}/helm_versions.json"
}

resource "helm_release" "as-server" {
  count      = module.cluster_autoscaler_version.version != null ? 1 : 0
  namespace  = "kube-system"
  name       = "autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = module.cluster_autoscaler_version.version

  values = [<<EOF
autoDiscovery:
  clusterName: ${data.terraform_remote_state.eks_core.outputs.cluster-name} 
  tags:
    - k8s.io/cluster-autoscaler/enabled
    - k8s.io/cluster-autoscaler/${data.terraform_remote_state.eks_core.outputs.cluster-name}
awsRegion: ${data.terraform_remote_state.network.outputs.region} 
cloudProvider: aws
deployment:
  annotations:
    cluster-autoscaler.kubernetes.io/safe-to-evict: "false"
extraArgs:
  scale-down-unneeded-time: 15m
  logtostderr: true
  stderrthreshold: info
  v: 4
  cloud-provider: aws
  skip-nodes-with-local-storage: false
  expander: least-waste
  balance-similar-node-groups: true
  skip-nodes-with-system-pods: false
  node-group-auto-discovery: asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/${data.terraform_remote_state.eks_core.outputs.cluster-name}
image:
  repository: registry.k8s.io/autoscaling/cluster-autoscaler
  tag: ${var.cluster_autoscaler_image_tag}
  pullPolicy: IfNotPresent
resources: 
  #limits:
  #  cpu: 100m
  #  memory: 300Mi
  requests:
    cpu: 100m
    memory: 100Mi  
nodeSelector:
  eks-cluster/nodegroup: ${data.terraform_remote_state.eks_core.outputs.nodegroup_prefix}-metrics
rbac:
  serviceAccount:
    name: "cluster-autoscaler"
EOF
  ]
}
