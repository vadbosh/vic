resource "helm_release" "victoria_metrics_cluster" {
  name       = "vm-cluster"
  repository = "https://victoriametrics.github.io/helm-charts/"
  chart      = "victoria-metrics-cluster"
  namespace  = "monitoring"
  #create_namespace = true
  version = "0.29.1" # Замените на актуальную версию
  timeout = "600"

  values = [
    <<-EOT
# --- vmstorage ---
vmstorage:
  replicaCount: 2
  nodeSelector:
    "eks-cluster/nodegroup": "${data.terraform_remote_state.eks_core.outputs.cluster-name}-victoria"
  resources:
    requests:
      cpu: "1000m"
      memory: "2Gi"
    limits:
      cpu: "1000m"
      memory: "4Gi"
  persistentVolume:
    enabled: true
    accessModes:
      - ReadWriteOnce
    storageClassName: "efs-sc"   
    size: 33Gi
# --- vmselect ---
vmselect:
  replicaCount: 2
  nodeSelector:
    "eks-cluster/nodegroup": "${data.terraform_remote_state.eks_core.outputs.cluster-name}-victoria"
  resources:
    requests:
      cpu: "500m"
      memory: "1Gi"
    limits:
      cpu: "1000m"
      memory: "1Gi"
# --- vminsert ---
vminsert:
  replicaCount: 2
  nodeSelector:
    "eks-cluster/nodegroup": "${data.terraform_remote_state.eks_core.outputs.cluster-name}-victoria"
  resources:
    requests:
      cpu: "500m"
      memory: "1Gi"
    limits:
      cpu: "1000m"
      memory: "1Gi"
EOT
  ]
}
