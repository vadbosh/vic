

resource "helm_release" "victoria_metrics_auth" {
  name       = "vm-auth"
  repository = "https://victoriametrics.github.io/helm-charts/"
  chart      = "victoria-metrics-auth"
  namespace  = "monitoring"
  #create_namespace = true
  version = "0.19.7"
  depends_on = [
    helm_release.victoria_metrics_cluster,
    kubernetes_secret_v1.vm_basic_auth_vic,
  ]
  values = [
    <<-EOT
nodeSelector:
  "eks-cluster/nodegroup": "${data.terraform_remote_state.eks_core.outputs.cluster-name}-victoria"
ingress:
  enabled: true
  ingressClassName: "shared-victoria"
  annotations:
    nginx.ingress.kubernetes.io/proxy-pass-headers: "WWW-Authenticate"
    nginx.ingress.kubernetes.io/proxy-http-version: "1.1"
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection $connection_upgrade;
      proxy_set_header Authorization $http_authorization;
  pathType: Prefix
  hosts:
    - name: victoria.wellnessliving.com
      path: /
      port: http
  tls:
    - hosts:
        - victoria.wellnessliving.com
      secretName: wellnessliving-com

config:
  users:
    - username: "${data.aws_ssm_parameter.username_vic.value}"
      password: "${data.aws_ssm_parameter.password_vic.value}"
      url_map:
        - src_paths:
            - "/select/.*"
          url_prefix: "http://vm-cluster-victoria-metrics-cluster-vmselect.monitoring.svc:8481"
        - src_paths:
            - "/select"
          url_prefix: "http://vm-cluster-victoria-metrics-cluster-vmselect.monitoring.svc:8481"
        - src_paths:
            - "/vmui.*"
          url_prefix: "http://vm-cluster-victoria-metrics-cluster-vmselect.monitoring.svc:8481"  
        - src_paths:
            - "/insert/.*"
          url_prefix: "http://vm-cluster-victoria-metrics-cluster-vminsert.monitoring.svc:8480"
        - src_paths:
            - "/insert"
          url_prefix: "http://vm-cluster-victoria-metrics-cluster-vminsert.monitoring.svc:8480"
        - src_paths:
            - "/admin/.*"
          url_prefix: "http://vm-cluster-victoria-metrics-cluster-vmselect.monitoring.svc:8481"  
  #unauthorized_user:
  #  url_map:
  #    #- src_paths:
  #    #    - "/select/.*"
  #    #  url_prefix: "http://vm-cluster-victoria-metrics-cluster-vmselect.monitoring.svc:8481"
  #    - src_paths:
  #        - "/insert/.*"
  #      url_prefix: "http://vm-cluster-victoria-metrics-cluster-vminsert.monitoring.svc:8480"
EOT
  ]
}


