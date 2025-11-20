# Этот файл управляет развертыванием стандартных экспортеров метрик.

# 1. Развертывание Kube State Metrics
/*
resource "helm_release" "kube_state_metrics" {
  name       = "kube-state-metrics"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-state-metrics"
  namespace  = "monitoring"
  version    = "6.4.1"
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
*/
# 2. Развертывание Node Exporter
resource "helm_release" "node_exporter" {
  name       = "node-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-node-exporter"
  namespace  = "monitoring"
  version    = "4.49.1"

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


# Artifact ID: exporters_fixed
# Branch: 1 (main) (019aa113...)
# Version: 1
# Command: create
# UUID: 0278f0b9-c5c6-43cd-8128-56fdf99620b2
# Created: 11/20/2025, 1:44:55 PM
# Change: Created

# ---

# exporters.tf
# Этот файл управляет развертыванием стандартных экспортеров метрик.

# 1. Развертывание Kube State Metrics
resource "helm_release" "kube_state_metrics" {
  name       = "kube-state-metrics"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-state-metrics"
  namespace  = "monitoring"
  version    = "6.4.1"
  timeout    = "180"

  values = [
    <<-EOT
# NodeSelector для размещения на нодах victoria
nodeSelector:
  "eks-cluster/nodegroup": "${data.terraform_remote_state.eks_core.outputs.cluster-name}-victoria"

# Service аннотации для scraping
service:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"

# КРИТИЧЕСКИ ВАЖНО: Мониторинг ВСЕХ namespaces
# Пустая строка означает "все namespaces"
namespaces: ""

# Альтернативный вариант - явно указать namespaces:
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

# RBAC - необходим для доступа ко всем namespaces
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

# Метрики и лейблы
# Можно ограничить какие лейблы собирать для снижения cardinality
metricLabelsAllowlist: []
# Пример ограничения:
# metricLabelsAllowlist:
#   - "pods=[app,env,version]"
#   - "deployments=[app,env]"

# Аннотации для сбора
metricAnnotationsAllowList: []

# Дополнительные аргументы для тонкой настройки
#extraArgs:
#  # Логирование
#  # Таймаут для API запросов
#  - --telemetry-port=8081
#  - --metric-denylist=kube_secret_labels,kube_secret_info
#  # ^ Исключаем секреты из метрик для безопасности

# Pod security context
#securityContext:
#  enabled: true
#  runAsUser: 65534
#  runAsGroup: 65534
#  fsGroup: 65534
#  runAsNonRoot: true

# Container security context
#containerSecurityContext:
#  allowPrivilegeEscalation: false
#  capabilities:
#    drop:
#      - ALL
#  readOnlyRootFilesystem: true

EOT
  ]
}


