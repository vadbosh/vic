# Файл: victoria-metrics-agent-token.tf

resource "helm_release" "victoria_metrics_agent_token" {
  name       = "vm-agent-token" # Уникальное имя релиза
  repository = "https://victoriametrics.github.io/helm-charts/"
  chart      = "victoria-metrics-agent"
  namespace  = "monitoring"
  version    = "0.26.4"
  timeout    = "120"

  depends_on = [
    helm_release.victoria_metrics_cluster,
    helm_release.victoria_metrics_auth,
    kubernetes_secret_v1.vm_bearer_token_secret
  ]

  values = [
    <<-EOT
replicaCount: 2 # !!!!
mode: statefulSet # !!!!

affinity:
  podAntiAffinity:
    # (hard constraint)
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels:
            app.kubernetes.io/name: victoria-metrics-agent
            app.kubernetes.io/instance: vm-agent-token
        topologyKey: kubernetes.io/hostname
    # (soft constraint)
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchLabels:
              app.kubernetes.io/name: victoria-metrics-agent
              app.kubernetes.io/instance: vm-agent-token
          topologyKey: topology.kubernetes.io/zone

resources:
  requests:
    cpu: "200m"
    memory: "256Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"
nodeSelector:
  "eks-cluster/nodegroup": "${data.terraform_remote_state.eks_core.outputs.cluster-name}-victoria"

service:
  enabled: true

ingress:
  enabled: true
  ingressClassName: "shared-victoria"
  annotations:
    nginx.ingress.kubernetes.io/auth-type: "basic"
    nginx.ingress.kubernetes.io/auth-secret: "vmagent-basic-auth"
    nginx.ingress.kubernetes.io/auth-realm: "Authentication Required - VM-Agent UI"
    nginx.ingress.kubernetes.io/proxy-http-version: "1.1"
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection $connection_upgrade;
  pathType: Prefix
  hosts:
    - name: vic-agent.wellnessliving.com
      path:
        - /
      port: http
  tls:
    - hosts:
        - vic-agent.wellnessliving.com
      secretName: wellnessliving-com
  

config:
  global:
    scrape_interval: 30s
    scrape_timeout: 10s

remoteWrite:
  - url: "http://vm-auth-victoria-metrics-auth.monitoring.svc:8427/insert/0/prometheus/api/v1/write"

persistentVolume:
  enabled: true
  storageClassName: "ebs-sc"
  accessModes:
    - ReadWriteOnce
  size: "5Gi"

extraArgs:
  remoteWrite.maxDiskUsagePerURL: "4294967296" # <-- IF EXIST persistentVolume ~4GB
  #remoteWrite.maxDiskUsagePerURL: "1073741824"
  promscrape.dropOriginalLabels: false
  envflag.enable: "true"
  envflag.prefix: VM_
  loggerFormat: json
  remoteWrite.bearerToken: "$(VM_BEARER_TOKEN)"

env:
  - name: VM_BEARER_TOKEN
    valueFrom:
      secretKeyRef:
        name: vm-bearer-token-secret
        key: token

EOT
  ]
}
