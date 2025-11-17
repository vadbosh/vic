module "cilium_version" {
  source             = "./modules/helm-version"
  chart_name         = "cilium"
  versions_file_path = "${path.root}/helm_versions.json"
}


resource "helm_release" "cilium" {
  count     = module.cilium_version.version != null ? 1 : 0
  namespace = "kube-system"
  wait      = true
  #create_namespace = true
  timeout    = "300"
  name       = "cilium"
  repository = "https://helm.cilium.io"
  chart      = "cilium"
  version    = module.cilium_version.version
  values = [<<EOF
cni:
  chainingMode: aws-cni
  exclusive: false
extraConfig:
  fqdn-regex-compile-lru-size: "65535"
enableIPv4Masquerade: false
routingMode: native
endpointRoutes:
  enabled: true
identityAllocationMode: crd
hubble:
  enabled: true 
  relay:
    enabled: true
  ui:
    enabled: false 
operator:
  #replicas: 2
  nodeSelector:
    eks-cluster/nodegroup: "${data.terraform_remote_state.eks_core.outputs.nodegroup_prefix}-ingress"
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: "app.kubernetes.io/name"
              operator: In
              values:
              - cilium-operator
          topologyKey: "topology.kubernetes.io/hostname"
EOF
  ]

}

