# Этот файл управляет развертыванием стандартных экспортеров метрик.

# 1. Развертывание Kube State Metrics
resource "helm_release" "kube_state_metrics" {
  name       = "kube-state-metrics"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-state-metrics"
  namespace  = "monitoring"
  version    = "6.3.0" # Рекомендуется закрепить версию
  values = [
    <<-EOT
nodeSelector:     
  "eks-cluster/nodegroup": "${data.terraform_remote_state.eks_core.outputs.cluster-name}-victoria"
service:
  annotations: 
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"  
collectors:
  - certificatesigningrequests
  - configmaps
  - cronjobs
  - daemonsets
  - deployments
  - endpoints
  - endpointslices
  - horizontalpodautoscalers
  - ingresses
  - jobs
  - leases
  - limitranges
  - mutatingwebhookconfigurations
  - namespaces
  - networkpolicies
  - nodes
  - persistentvolumeclaims
  - persistentvolumes
  - poddisruptionbudgets
  - pods
  - replicasets
  - replicationcontrollers
  - resourcequotas
  - secrets
  - services
  - statefulsets
  - storageclasses
  - validatingwebhookconfigurations
  - volumeattachments
EOT
  ]
}

# 2. Развертывание Node Exporter
resource "helm_release" "node_exporter" {
  name       = "node-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-node-exporter"
  namespace  = "monitoring"
  version    = "4.48.0" # Рекомендуется закрепить версию

  # Node Exporter также создает ServiceMonitor по умолчанию.

  values = [
    <<-EOT
service:
  enabled: true
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "9100"
EOT
  ]
}
