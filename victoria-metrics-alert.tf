
resource "kubernetes_config_map_v1" "vmalert_rules" {
  metadata {
    name      = "vmalert-rules"
    namespace = "monitoring"
  }
  data = {
    "alert-rules.yaml" = file("${path.module}/alert-rules/alerts.yaml")
  }
}

resource "helm_release" "victoria_metrics_alert" {
  name       = "vm-alert"
  repository = "https://victoriametrics.github.io/helm-charts/"
  chart      = "victoria-metrics-alert"
  namespace  = "monitoring"
  version    = "0.26.6"
  timeout    = "120"

  depends_on = [
    helm_release.victoria_metrics_cluster,
    helm_release.victoria_metrics_auth,
    kubernetes_config_map_v1.vmalert_rules,
    kubernetes_secret_v1.vm_bearer_token_secret
  ]


  values = [
    <<-EOT
server:
  #name: vmalert
  datasource:
    #url: "http://vm-cluster-victoria-metrics-cluster-vmselect.monitoring.svc:8481/select/0/prometheus/"
    url: "http://vm-auth-victoria-metrics-auth.monitoring.svc:8427/select/0/prometheus"
  remote:
    write:
      #url: "http://vm-cluster-victoria-metrics-cluster-vminsert.monitoring.svc:8480/insert/0/prometheus/api/v1/write"
      url: "http://vm-auth-victoria-metrics-auth.monitoring.svc:8427/insert/0/prometheus"
      #url: "http://vm-auth-victoria-metrics-auth.monitoring.svc:8427/insert/0/prometheus/api/v1/write"
    read:
      #url: "http://vm-cluster-victoria-metrics-cluster-vmselect.monitoring.svc:8481/select/0/prometheus/"
      url: "http://vm-auth-victoria-metrics-auth.monitoring.svc:8427/select/0/prometheus"
  notifier:
    alertmanager:
      url: "http://vm-alert-victoria-metrics-alert-alertmanager.monitoring.svc:9093"

  configMap: "vmalert-rules"

  extraArgs:
    configCheckInterval: 60s
    datasource.bearerToken: "${data.aws_ssm_parameter.vmagent_bearer_token.value}"
    remoteWrite.bearerToken: "${data.aws_ssm_parameter.vmagent_bearer_token.value}"
    remoteRead.bearerToken: "${data.aws_ssm_parameter.vmagent_bearer_token.value}"

  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "500m"
      memory: "512Mi"
  
  nodeSelector:
    "eks-cluster/nodegroup": "${data.terraform_remote_state.eks_core.outputs.cluster-name}-victoria"
  
  ingress:
    enabled: true
    ingressClassName: "shared-victoria"
    annotations:
      nginx.ingress.kubernetes.io/auth-type: "basic"
      nginx.ingress.kubernetes.io/auth-secret: "vmagent-basic-auth" 
      nginx.ingress.kubernetes.io/auth-realm: "Auth"
    pathType: Prefix
    hosts:
      - name: vmalert.wellnessliving.com
        path: /
        port: http
    tls:
      - hosts:
          - vmalert.wellnessliving.com
        secretName: wellnessliving-com

alertmanager:
  enabled: true
  retention: 120h
  listenAddress: "0.0.0.0:9093"
  extraArgs: {}
  envFrom: []
  baseURL: ""
  baseURLPrefix: ""
  configMap: ""
  webConfig: {}
  config:
    global:
      resolve_timeout: 30s
    route:
      group_by: ['pod','alertname']  
      group_wait: 5s
      group_interval: 5m
      repeat_interval: 20m
      receiver: WL-warning-condition 
      routes:
      - receiver: WL-warning-condition
        group_by: ['alertname', 'pod', 'image']
        group_wait: 5s
        matchers:
          - severity=warning
        continue: true
      - receiver: WL-PODS-condition 
        group_by: ['pod']
        matchers:
          - podstat=~stoppod|startpod|resource_stats_mem|resource_stats_cpu
        continue: true
      - receiver: WL-critical-condition
        group_by: ['alertname', 'pod', 'image']
        repeat_interval: 5m
        matchers:
          - severity=critical
        continue: true
      - receiver: 'null'
        matchers:
          - severity=~"info|none|"
    
    receivers:
    - name: WL-PODS-condition
      telegram_configs:
      - send_resolved: false
        bot_token: "8356221553:AAGINYWYpGyO4OkTNFVMXEjIJh9CwUEPjPc"
        chat_id: -5079754285
        api_url: "https://api.telegram.org"
        parse_mode: HTML
        message: |
          {{ range .Alerts }}
              {{ if eq .Labels.podstat "startpod"}}&#128640;  <b>{{ .Labels.podstat | toUpper }}</b> {{ else }}&#128310;  <b>{{ .Labels.podstat | toUpper }}</b> {{ end }} 
              &#9201; <b>StartAt:</b> {{ printf "%s\n" .StartsAt }}
              {{- if .Annotations.description }}<b>Description:</b>  {{ printf "%s\n" .Annotations.description }}{{ end }}
              {{- if .Labels.instance }}<b>Instance:</b>  {{ printf "%s\n" .Labels.instance }}{{ end }}
              {{- if .Labels.namespace }}<b>Namespace:</b>  {{ printf "%s\n" .Labels.namespace }}{{ end }}
              {{- if .Labels.image }}<b>Image:</b> ● {{ printf "%s ●\n" .Labels.image }}{{ end }}
              {{- if .Labels.pod }}&#128313; <b>Pod:</b>  {{ printf "%s\n" .Labels.pod }}{{ end }}
              {{- if .Labels.deployment }}<b>Deployment:</b>  {{ printf "%s\n" .Labels.deployment }}{{ end }}
              {{- if .Labels.container }}<b>Container:</b>  {{ printf "%s\n" .Labels.container }}{{ end }}
              {{- if .Labels.host }}<b>Host:</b>  {{ printf "%s\n" .Labels.host }}{{ end }}
              {{- if .Labels.node }}<b>Node:</b>  {{ printf "%s\n" .Labels.node }}{{ end }}
              {{- if .Labels.reason }}<b>Reason:</b>  {{ printf "%s\n" .Labels.reason }}{{ end }}
          {{ end }}
    
    - name: WL-critical-condition 
      telegram_configs:
      - send_resolved: true 
        bot_token: "8356221553:AAGINYWYpGyO4OkTNFVMXEjIJh9CwUEPjPc"
        chat_id: -5079754285
        api_url: "https://api.telegram.org"
        parse_mode: HTML
        message: |
          {{ if eq .Status "firing"}}&#128293;  <b>{{ .Status | toUpper }} {{ .CommonLabels.alertname }}</b> {{ else }}&#127808;  <b>{{ .Status | toUpper }} {{ .CommonLabels.alertname }}</b> {{ end }} 
          {{ range .Alerts }}
              &#9201; <b>StartAt:</b> {{ .StartsAt }}
              {{ if ne .Status "firing"}}&#9201; <b>Ended:</b> {{ .EndsAt }}{{ end }}
              ●  <b>Alert:</b>  {{ printf "%s  ●\n" .Labels.severity }}
              {{- if .Annotations.description }}<b>Description:</b>  {{ printf "%s\n" .Annotations.description }}{{ end }}
              {{- if .Labels.instance }}<b>Instance:</b>  {{ printf "%s\n" .Labels.instance }}{{ end }}
              {{- if .Labels.namespace }}<b>Namespace:</b>  {{ printf "%s\n" .Labels.namespace }}{{ end }}
              {{- if .Labels.image }}<b>Image:</b> ● {{ printf "%s ●\n" .Labels.image }}{{ end }}
              {{- if .Labels.pod }}&#128313; <b>Pod:</b>  {{ printf "%s\n" .Labels.pod }}{{ end }}
              {{- if .Labels.deployment }}<b>Deployment:</b>  {{ printf "%s\n" .Labels.deployment }}{{ end }}
              {{- if .Labels.container }}<b>Container:</b>  {{ printf "%s\n" .Labels.container }}{{ end }}
              {{- if .Labels.integration }}<b>Integration:</b>  {{ printf "%s\n" .Labels.integration }}{{ end }}
              {{- if .Labels.horizontalpodautoscaler }}<b>HPautoscaler for:</b>  {{ printf "%s\n" .Labels.horizontalpodautoscaler }}{{ end }}
              {{- if .Labels.host }}<b>Host:</b>  {{ printf "%s\n" .Labels.host }}{{ end }}
              {{- if .Labels.node }}<b>Node:</b>  {{ printf "%s\n" .Labels.node }}{{ end }}
              {{- if .Labels.reason }}<b>Reason:</b>  {{ printf "%s\n" .Labels.reason }}{{ end }}
          {{ end }}
    
    - name: WL-warning-condition
      telegram_configs:
      - send_resolved: true
        bot_token: "8356221553:AAGINYWYpGyO4OkTNFVMXEjIJh9CwUEPjPc"
        chat_id: -5079754285
        api_url: "https://api.telegram.org"
        parse_mode: HTML
        message: |
          {{ if eq .Status "firing"}}&#128681;  <b>{{ .Status | toUpper }} {{ .CommonLabels.alertname }}</b> {{ else }}&#127808;  <b>{{ .Status | toUpper }} {{ .CommonLabels.alertname }}</b> {{ end }} 
          {{ range .Alerts }}
              &#9201; <b>StartAt:</b> {{ .StartsAt }}
              {{ if ne .Status "firing"}}&#9201; <b>Ended:</b> {{ .EndsAt }}{{ end }}
              ●  <b>Alert:</b>  {{ printf "%s  ●\n" .Labels.severity }}
              {{- if .Annotations.description }}<b>Description:</b> {{ printf "%s\n" .Annotations.description }}{{ end }}
              {{- if .Labels.instance }}<b>Instance:</b>  {{ printf "%s\n" .Labels.instance }}{{ end }}
              {{- if .Labels.namespace }}<b>Namespace:</b>  {{ printf "%s\n" .Labels.namespace }}{{ end }}
              {{- if .Labels.image }}<b>Image:</b> ● {{ printf "%s ●\n" .Labels.image }}{{ end }}
              {{- if .Labels.pod }}&#128313; <b>Pod:</b>  {{ printf "%s\n" .Labels.pod }}{{ end }}
              {{- if .Labels.deployment }}<b>Deployment:</b>  {{ printf "%s\n" .Labels.deployment }}{{ end }}
              {{- if .Labels.container }}<b>Container:</b>  {{ printf "%s\n" .Labels.container }}{{ end }}
              {{- if .Labels.integration }}<b>Integration:</b>  {{ printf "%s\n" .Labels.integration }}{{ end }}
              {{- if .Labels.horizontalpodautoscaler }}<b>HPautoscaler for:</b>  {{ printf "%s\n" .Labels.horizontalpodautoscaler }}{{ end }}
              {{- if .Labels.host }}<b>Host:</b>  {{ printf "%s\n" .Labels.host }}{{ end }}
              {{- if .Labels.node }}<b>Node:</b>  {{ printf "%s\n" .Labels.node }}{{ end }}
              {{- if .Labels.reason }}<b>Reason:</b>  {{ printf "%s\n" .Labels.reason }}{{ end }}  
          {{ end }}
    
    - name: 'null'
  
  resources:
    requests:
      cpu: "250m"
      memory: "128Mi"
    limits:
      cpu: "500m"
      memory: "256Mi"
  nodeSelector:
    "eks-cluster/nodegroup": "${data.terraform_remote_state.eks_core.outputs.cluster-name}-victoria"
  ingress:
    enabled: true
    ingressClassName: "shared-victoria"
    annotations:
      nginx.ingress.kubernetes.io/auth-type: "basic"
      nginx.ingress.kubernetes.io/auth-secret: "vmagent-basic-auth"
      nginx.ingress.kubernetes.io/auth-realm: "Auth"
    pathType: Prefix
    hosts:
      - name: alertmanager.wellnessliving.com
        path: /
        port: http
    tls:
      - hosts:
          - alertmanager.wellnessliving.com
        secretName: wellnessliving-com

EOT
  ]
}

