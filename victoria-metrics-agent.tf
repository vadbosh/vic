
resource "helm_release" "victoria_metrics_agent" {
  name       = "vm-agent"
  repository = "https://victoriametrics.github.io/helm-charts/"
  chart      = "victoria-metrics-agent"
  namespace  = "monitoring"
  # create_namespace = true
  version = "0.26.2"

  depends_on = [
    helm_release.victoria_metrics_cluster,
    helm_release.victoria_metrics_auth,
    kubernetes_secret_v1.vm_basic_auth_vic
  ]

  values = [
    <<-EOT
replicaCount: 2
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
    #nginx.ingress.kubernetes.io/proxy-pass-headers: "WWW-Authenticate"
    nginx.ingress.kubernetes.io/proxy-http-version: "1.1"
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection $connection_upgrade;
      #proxy_set_header Authorization $http_authorization;
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


remoteWrite:
  - url: "http://vm-auth-victoria-metrics-auth.monitoring.svc:8427/insert/0/prometheus/api/v1/write"

extraArgs:
  envflag.enable: "true"
  envflag.prefix: VM_
  loggerFormat: json
  promscrape.dropOriginalLabels: false

env:
  - name: VM_remoteWrite_basicAuth_username
    valueFrom:
      secretKeyRef:
        name: vm-basic-auth-secret
        key: username
  - name: VM_remoteWrite_basicAuth_password
    valueFrom:
      secretKeyRef:
        name: vm-basic-auth-secret
        key: password

EOT
  ]
}


