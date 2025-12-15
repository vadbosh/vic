#  Node Exporter
resource "helm_release" "node_exporter" {
  name       = "node-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-node-exporter"
  namespace  = "monitoring"
  version    = "4.49.2"

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

#  Kube State Metrics
resource "helm_release" "kube_state_metrics" {
  name       = "kube-state-metrics"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-state-metrics"
  namespace  = "monitoring"
  version    = "6.4.2"
  timeout    = "180"

  values = [
    <<-EOT
nodeSelector:
  "eks-cluster/nodegroup": "${data.terraform_remote_state.eks_core.outputs.cluster-name}-victoria"

# Service аннотации для scraping
service:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"

#  "All namespaces"
namespaces: ""
#namespaces: "default,kube-system,monitoring,production,staging,ingress-nginx"

# Список коллекторов метрик
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

rbac:
  create: true

# ServiceAccount
serviceAccount:
  create: true
  name: kube-state-metrics

# Ресурсы
resources:
  requests:
    cpu: "100m"
    memory: "256Mi"
  limits:
    cpu: "200m"
    memory: "512Mi"

metricAnnotationsAllowList: []

# Pod security context
#securityContext:
#  enabled: true
#  runAsUser: 65534
#  runAsGroup: 65534
#  fsGroup: 65534
#  runAsNonRoot: true

EOT
  ]
}


