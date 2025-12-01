# severity: critical4sns -> SNS, severity: critical -> Telegram


resource "kubernetes_service_account_v1" "alertmanager_sa" {
  metadata {
    name        = local.service_account.victoria_metrics_alert
    namespace   = "monitoring"
    annotations = {}
  }
  automount_service_account_token = true
}


locals {
  alert_rule_dirs = toset([
    "critical",
    "del",
    "info",
    "sns",
    "warning"
  ])
}

resource "kubernetes_config_map_v1" "vmalert_rules_dynamic" {
  for_each = local.alert_rule_dirs

  metadata {
    name      = "vmalert-rules-${each.key}"
    namespace = "monitoring"
    labels = {
      "app.kubernetes.io/name"      = "vmalert"
      "app.kubernetes.io/component" = "alert-rules"
      "alert-category"              = each.key
    }
  }

  data = {
    for file in try(fileset("${path.module}/alert-rules/${each.key}", "*.yaml"), []) :
    file => file("${path.module}/alert-rules/${each.key}/${file}")
  }
}

/*
resource "kubernetes_config_map_v1" "vmalert_rules" {
  metadata {
    name      = "vmalert-rules"
    namespace = "monitoring"
  }
  data = {
    "alert-rules.yaml" = file("${path.module}/alert-rules/alerts.yaml")
  }
}
*/

resource "helm_release" "victoria_metrics_alert" {
  name       = "vm-alert"
  repository = "https://victoriametrics.github.io/helm-charts/"
  chart      = "victoria-metrics-alert"
  namespace  = "monitoring"
  version    = "0.26.6"
  timeout    = "120"

  #kubernetes_config_map_v1.vmalert_rules,

  depends_on = [
    helm_release.victoria_metrics_cluster,
    helm_release.victoria_metrics_auth,
    kubernetes_secret_v1.vm_bearer_token_secret,
    kubernetes_service_account_v1.alertmanager_sa,
    aws_eks_pod_identity_association.alertmanager_sns,
    kubernetes_config_map_v1.vmalert_rules_dynamic
  ]

  values = [
    <<-EOT
serviceAccount:
  create: false
  name: "${local.service_account.victoria_metrics_alert}"
  #annotations: {}

server:
  datasource:
    url: "http://vm-auth-victoria-metrics-auth.monitoring.svc:8427/select/0/prometheus"
  remote:
    write:
      url: "http://vm-auth-victoria-metrics-auth.monitoring.svc:8427/insert/0/prometheus"
    read:
      url: "http://vm-auth-victoria-metrics-auth.monitoring.svc:8427/select/0/prometheus"
  notifier:
    alertmanager:
      url: "http://vm-alert-victoria-metrics-alert-alertmanager:9093"

  #configMap: "vmalert-rules"

  env:
    - name: DATASOURCE_BEARER_TOKEN
      valueFrom:
        secretKeyRef:
          name: "${local.bearer_token_secret.name}"
          key: token

  extraArgs:
    configCheckInterval: 60s
    external.alert.source: "${data.terraform_remote_state.eks_core.outputs.cluster-name}"
    datasource.bearerToken: "$(DATASOURCE_BEARER_TOKEN)"
    remoteWrite.bearerToken: "$(DATASOURCE_BEARER_TOKEN)"
    remoteRead.bearerToken: "$(DATASOURCE_BEARER_TOKEN)"
    #datasource.bearerToken: "${data.aws_ssm_parameter.vmagent_bearer_token.value}"
    #remoteWrite.bearerToken: "${data.aws_ssm_parameter.vmagent_bearer_token.value}"
    #remoteRead.bearerToken: "${data.aws_ssm_parameter.vmagent_bearer_token.value}"
    rule: |
      /etc/vm/rules/*/*.yaml

  configMaps:
    - vmalert-rules-critical
    - vmalert-rules-del
    - vmalert-rules-info
    - vmalert-rules-sns
    - vmalert-rules-warning
    - vmalert-rules-security

  # Альтернативный способ через extraVolumes/extraVolumeMounts
  extraVolumes:
    - name: rules-critical
      configMap:
        name: vmalert-rules-critical
    - name: rules-del
      configMap:
        name: vmalert-rules-del
    - name: rules-info
      configMap:
        name: vmalert-rules-info
    - name: rules-sns
      configMap:
        name: vmalert-rules-sns
    - name: rules-warning
      configMap:
        name: vmalert-rules-warning

  extraVolumeMounts:
    - name: rules-critical
      mountPath: /etc/vm/rules/critical
      readOnly: true
    - name: rules-del
      mountPath: /etc/vm/rules/del
      readOnly: true
    - name: rules-info
      mountPath: /etc/vm/rules/info
      readOnly: true
    - name: rules-sns
      mountPath: /etc/vm/rules/sns
      readOnly: true
    - name: rules-warning
      mountPath: /etc/vm/rules/warning
      readOnly: true

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
      nginx.ingress.kubernetes.io/auth-secret: "${local.basic_auth_secret.name}"
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

  env:
    - name: AWS_REGION
      value: "${data.terraform_remote_state.network.outputs.region}"

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
      # ПРИОРИТЕТ 1: Алерты для SNS (severity: critical4sns)
      - receiver: WL-critical4sns-condition
        group_by: ['alertname', 'pod', 'image']
        repeat_interval: 5m
        matchers:
          - severity=critical4sns
        continue: false

      # ПРИОРИТЕТ 2: Обычные критические алерты в Telegram (severity: critical)
      - receiver: WL-critical-condition
        group_by: ['alertname', 'pod', 'image']
        repeat_interval: 5m
        matchers:
          - severity=critical
        continue: true

      # ПРИОРИТЕТ 3: Warning алерты
      - receiver: WL-warning-condition
        group_by: ['alertname', 'pod', 'image']
        group_wait: 5s
        matchers:
          - severity=warning
        continue: true

      # ПРИОРИТЕТ 4: Pod статусы
      - receiver: WL-PODS-condition
        group_by: ['pod']
        matchers:
          - podstat=~stoppod|startpod|resource_stats_mem|resource_stats_cpu
        continue: true

      # ПРИОРИТЕТ 5: Игнорируемые алерты
      - receiver: 'null'
        matchers:
          - severity=~"info|none|"

    receivers:
    # НОВЫЙ RECEIVER: critical4sns -> ТОЛЬКО SNS (без Telegram)
    - name: WL-critical4sns-condition
      sns_configs:
      - api_url: "https://sns.us-east-1.amazonaws.com"
        topic_arn: "${data.aws_sns_topic.existing_sns.arn}"
        sigv4:
          region: "${data.terraform_remote_state.network.outputs.region}"
        subject: "🚨 CRITICAL SNS ALERT: {{ .GroupLabels.alertname }}"
        message: |
          ═══════════════════════════════════════
          🚨 CRITICAL ALERT (SNS)
          ═══════════════════════════════════════

          Status: {{ .Status | toUpper }}
          Alert Name: {{ .GroupLabels.alertname }}
          Severity: CRITICAL4SNS
          Cluster: ${data.terraform_remote_state.eks_core.outputs.cluster-name}
          Environment: sandbox

          {{ range .Alerts }}
          ───────────────────────────────────────
          ⏰ Started: {{ .StartsAt }}
          {{ if ne .Status "firing" }}⏰ Ended: {{ .EndsAt }}{{ end }}

          📝 Description:
          {{ .Annotations.description }}

          🔍 Details:
          {{ if .Labels.instance }}  • Instance: {{ .Labels.instance }}{{ end }}
          {{ if .Labels.namespace }}  • Namespace: {{ .Labels.namespace }}{{ end }}
          {{ if .Labels.pod }}  • Pod: {{ .Labels.pod }}{{ end }}
          {{ if .Labels.deployment }}  • Deployment: {{ .Labels.deployment }}{{ end }}
          {{ if .Labels.container }}  • Container: {{ .Labels.container }}{{ end }}
          {{ if .Labels.node }}  • Node: {{ .Labels.node }}{{ end }}
          {{ if .Labels.image }}  • Image: {{ .Labels.image }}{{ end }}
          {{ end }}

          ═══════════════════════════════════════
        attributes:
          cluster: "${data.terraform_remote_state.eks_core.outputs.cluster-name}"
          severity: "critical4sns"
          environment: "sandbox"

    # СУЩЕСТВУЮЩИЙ RECEIVER: critical -> Telegram
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
      nginx.ingress.kubernetes.io/auth-secret: "${local.basic_auth_secret.name}"
      nginx.ingress.kubernetes.io/auth-realm: "Auth"
      nginx.ingress.kubernetes.io/proxy-http-version: "1.1"
    pathType: Prefix
    hosts:
      - name: alertmanager.wellnessliving.com
        path:
          - /
        port: web
    tls:
      - hosts:
          - alertmanager.wellnessliving.com
        secretName: wellnessliving-com
EOT
  ]
}

