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
    "cluster",
    "ingress",
    "service",
    "sns"
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
  version    = "0.27.0"
  timeout    = "180"

  #kubernetes_config_map_v1.vmalert_rules,

  depends_on = [
    helm_release.victoria_metrics_cluster,
    helm_release.victoria_metrics_auth,
    kubernetes_secret_v1.vm_bearer_token_secret,
    kubernetes_secret_v1.telegram_credentials,
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
      url: "http://vm-alert-victoria-metrics-alert-alertmanager.monitoring.svc.cluster.local:9093"

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
    - vmalert-rules-cluster
    - vmalert-rules-ingress
    - vmalert-rules-service
    - vmalert-rules-sns

  extraVolumes:
    - name: rules-cluster
      configMap:
        name: vmalert-rules-cluster
    - name: rules-ingress
      configMap:
        name: vmalert-rules-ingress
    - name: rules-service
      configMap:
        name: vmalert-rules-service
    - name: rules-sns
      configMap:
        name: vmalert-rules-sns

  extraVolumeMounts:
    - name: rules-cluster
      mountPath: /etc/vm/rules/cluster
      readOnly: true
    - name: rules-ingress
      mountPath: /etc/vm/rules/ingress
      readOnly: true
    - name: rules-service
      mountPath: /etc/vm/rules/service
      readOnly: true
    - name: rules-sns
      mountPath: /etc/vm/rules/sns
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

  extraVolumes:
    - name: telegram-secret
      secret:
        secretName: telegram-alertmanager-credentials
  extraVolumeMounts:
    - name: telegram-secret
      mountPath: /etc/secrets/telegram
      readOnly: true

  env:
    - name: AWS_REGION
      value: "${data.terraform_remote_state.network.outputs.region}"
    #- name: TELEGRAM_BOT_TOKEN
    #  valueFrom:
    #    secretKeyRef:
    #      name: telegram-alertmanager-credentials
    #      key: bot-token
    #
  config:
    global:
      resolve_timeout: 30s

    route:
      # Root level grouping - keeps related alerts together
      group_by: ['alertname']
      group_wait: 30s       # Wait 5s before sending first notification in group
      group_interval: 5m    # Wait 5m before sending new alerts that belong to existing group
      repeat_interval: 20m  # Resend firing alerts every 20m
      receiver: 'null'      # Default receiver for unmatched alerts

      routes:
      # ============================================================
      # PRIORITY 1: SNS Alerts (severity: critical4sns)
      # ============================================================
      # These go ONLY to SNS, not Telegram
      # continue: false = stop processing after match
      - receiver: WL-critical4sns-condition
        group_by: ['alertname', 'namespace', 'exported_namespace', 'pod', 'exported_pod', 'host']
        group_wait: 30s
        group_interval: 5m
        repeat_interval: 5m
        matchers:
          - severity=critical4sns
        continue: false  # FIXED: Stop here, don't send to other receivers

      # ============================================================
      # PRIORITY 2: Critical Alerts (severity: critical)
      # ============================================================
      # These go to Telegram only
      - receiver: WL-critical-condition
        group_by: ['alertname', 'namespace', 'exported_namespace', 'pod', 'exported_pod', 'host']
        group_wait: 30s
        group_interval: 5m
        repeat_interval: 5m
        matchers:
          - severity=critical
        continue: false  # FIXED: Stop here

      # ============================================================
      # PRIORITY 3: Warning Alerts (severity: warning)
      # ============================================================
      - receiver: WL-warning-condition
        group_by: ['alertname', 'namespace', 'exported_namespace', 'pod', 'exported_pod', 'host']
        group_wait: 30s
        group_interval: 5m
        repeat_interval: 15m
        matchers:
          - severity=warning
        continue: false  # FIXED: Stop here

      # ============================================================
      # PRIORITY 4: Pod Status Notifications (podstat label)
      # ============================================================
      # Special case for pod lifecycle events
      - receiver: WL-PODS-condition
        group_by: ['pod', 'exported_pod', 'namespace']
        group_wait: 30s
        group_interval: 2m
        repeat_interval: 1h
        matchers:
          - podstat=~"stoppod|startpod|resource_stats_mem|resource_stats_cpu"
        continue: false  # FIXED: Stop here

      # ============================================================
      # PRIORITY 5: Info/None severity (suppress)
      # ============================================================
      - receiver: 'null'
        matchers:
          - severity=~"info|none|"
        continue: false

    # ============================================================
    # RECEIVERS CONFIGURATION
    # ============================================================
    receivers:
    # SNS Receiver (for critical4sns severity only)
    - name: WL-critical4sns-condition
      sns_configs:
      - api_url: "https://sns.us-east-1.amazonaws.com"
        topic_arn: "${data.aws_sns_topic.existing_sns.arn}"
        sigv4:
          region: "${data.terraform_remote_state.network.outputs.region}"
        subject: "CRITICAL: {{ .GroupLabels.alertname }}"
        message: |
          {{ if eq .Status "firing" }}🔥 FIRING{{ else }}✅ RESOLVED{{ end }}: {{ .GroupLabels.alertname }}
          Cluster: ${data.terraform_remote_state.eks_core.outputs.cluster-name}
          Severity: {{ printf "%s\n" .CommonLabels.severity }}
          {{ range .Alerts }}
          ⏰ Started: {{ .StartsAt.Format "2006-01-02 15:04:05 MST" }}
          {{ if ne .Status "firing" }}⏰ Ended: {{ .EndsAt.Format "2006-01-02 15:04:05 MST" }}{{ printf "\n" }}{{ end }}
          📋 Summary: {{ .Annotations.summary }}
          📝 Description: {{ .Annotations.description }}
          🔍 Details:{{ printf "\n" }}
          {{- if .Labels.namespace }}  • Namespace: {{ printf "%s\n" .Labels.namespace }}{{ end }}
          {{- if .Labels.exported_namespace }}  • Namespace: {{ printf "%s\n" .Labels.exported_namespace }}{{ end }}
          {{- if .Labels.pod }}  • Pod: {{ printf "%s\n" .Labels.pod }}{{ end }}
          {{- if .Labels.exported_pod }}  • Pod: {{ printf "%s\n" .Labels.exported_pod }}{{ end }}
          {{- if .Labels.host }}  • Host: {{ printf "%s\n" .Labels.host }}{{ end }}
          {{- if .Labels.instance }}  • Instance: {{ printf "%s\n" .Labels.instance }}{{ end }}
          {{- if .Labels.deployment }}  • Deployment: {{ printf "%s\n" .Labels.deployment }}{{ end }}
          {{- if .Labels.container }}  • Container: {{ printf "%s\n" .Labels.container }}{{ end }}
          {{- if .Labels.node }}  • Node: {{ printf "%s\n" .Labels.node }}{{ end }}
          {{- if .Labels.image }}  • Image: {{ printf "%s\n" .Labels.image }}{{ end }}
          {{ end }}
        attributes:
          cluster: "${data.terraform_remote_state.eks_core.outputs.cluster-name}"
          severity: "critical4sns"

    # Telegram Receiver for Critical alerts
    - name: WL-critical-condition
      telegram_configs:
      - send_resolved: true
        bot_token_file: "/etc/secrets/telegram/bot-token"
        chat_id: -5079754285
        api_url: "https://api.telegram.org"
        parse_mode: HTML
        message: |
          {{ if eq .Status "firing"}}🔥{{ else }}✅{{ end }} <b>{{ .Status | toUpper }}: {{ .GroupLabels.alertname }}</b>
          💥 <b>Severity:</b>  ◆ {{ printf "%s ◆\n" .CommonLabels.severity }}
          ⏰ <b>Started:</b> {{ (index .Alerts 0).StartsAt.Format "2006-01-02 15:04:05 MST" }}
          {{ if ne .Status "firing"}}⏰ <b>Ended:</b> {{ (index .Alerts 0).EndsAt.Format "2006-01-02 15:04:05 MST" }}{{ printf "\n" }}{{ end }}
          {{- if .CommonAnnotations.summary }}📋 <b>Summary:</b> {{ printf "%s\n" .CommonAnnotations.summary }}{{ end }}
          {{- if .CommonAnnotations.description }}📝 <b>Description:</b> {{ printf "%s\n" .CommonAnnotations.description }}{{ end }}
          {{ range .Alerts }}
          {{- if .Labels.namespace }}🏷 <b>Namespace:</b> {{ printf "%s\n" .Labels.namespace }}{{ end }}
          {{- if .Labels.exported_namespace }}🏷 <b>Namespace:</b> {{ printf "%s\n" .Labels.exported_namespace }}{{ end }}
          {{- if .Labels.pod }}📦 <b>Pod:</b> {{ printf "%s\n" .Labels.pod }}{{ end }}
          {{- if .Labels.exported_pod }}📦 <b>Pod:</b> {{ printf "%s\n" .Labels.exported_pod }}{{ end }}
          {{- if .Labels.host }}🌐 <b>Host:</b> {{ printf "%s\n" .Labels.host }}{{ end }}
          {{- if .Labels.instance }}🖥 <b>Instance:</b> {{ printf "%s\n" .Labels.instance }}{{ end }}
          {{- if .Labels.deployment }}🚀 <b>Deployment:</b> {{ printf "%s\n" .Labels.deployment }}{{ end }}
          {{- if .Labels.container }}📦 <b>Container:</b> {{ printf "%s\n" .Labels.container }}{{ end }}
          {{- if .Labels.node }}🖥 <b>Node:</b> {{ printf "%s\n" .Labels.node }}{{ end }}
          {{- if .Labels.horizontalpodautoscaler }}⚖️ <b>HPA:</b> {{ printf "%s\n" .Labels.horizontalpodautoscaler }}{{ end }}
          {{- if .Labels.image }}🐳 <b>Image:</b> {{ printf "%s\n" .Labels.image }}{{ end }}
          {{- if .Labels.reason }}❓ <b>Reason:</b> {{ printf "%s\n" .Labels.reason }}{{ end }}
          {{ end }}

    # Telegram Receiver for Warning alerts
    - name: WL-warning-condition
      telegram_configs:
      - send_resolved: true
        bot_token_file: "/etc/secrets/telegram/bot-token"
        chat_id: -5079754285
        api_url: "https://api.telegram.org"
        parse_mode: HTML
        message: |
          {{ if eq .Status "firing"}}⚠️{{ else }}✅{{ end }} <b>{{ .Status | toUpper }}: {{ .GroupLabels.alertname }}</b>
          🔔 <b>Severity:</b>  ◆ {{ printf "%s ◆\n" .CommonLabels.severity }}
          ⏰ <b>Started:</b> {{ (index .Alerts 0).StartsAt.Format "2006-01-02 15:04:05 MST" }}
          {{ if ne .Status "firing"}}⏰ <b>Ended:</b> {{ (index .Alerts 0).EndsAt.Format "2006-01-02 15:04:05 MST" }}{{ printf "\n" }}{{ end }}
          {{- if .CommonAnnotations.summary }}📋 <b>Summary:</b> {{ printf "%s\n" .CommonAnnotations.summary }}{{ end }}
          {{- if .CommonAnnotations.description }}📝 <b>Description:</b> {{ printf "%s\n" .CommonAnnotations.description }}{{ end }}
          {{ range .Alerts }}
          {{- if .Labels.namespace }}🏷 <b>Namespace:</b> {{ printf "%s\n" .Labels.namespace }}{{ end }}
          {{- if .Labels.exported_namespace }}🏷 <b>Namespace:</b> {{ printf "%s\n" .Labels.exported_namespace }}{{ end }}
          {{- if .Labels.pod }}📦 <b>Pod:</b> {{ printf "%s\n" .Labels.pod }}{{ end }}
          {{- if .Labels.exported_pod }}📦 <b>Pod:</b> {{ printf "%s\n" .Labels.exported_pod }}{{ end }}
          {{- if .Labels.host }}🌐 <b>Host:</b> {{ printf "%s\n" .Labels.host }}{{ end }}
          {{- if .Labels.instance }}🖥 <b>Instance:</b> {{ printf "%s\n" .Labels.instance }}{{ end }}
          {{- if .Labels.deployment }}🚀 <b>Deployment:</b> {{ printf "%s\n" .Labels.deployment }}{{ end }}
          {{- if .Labels.container }}📦 <b>Container:</b> {{ printf "%s\n" .Labels.container }}{{ end }}
          {{- if .Labels.node }}🖥 <b>Node:</b> {{ printf "%s\n" .Labels.node }}{{ end }}
          {{- if .Labels.horizontalpodautoscaler }}⚖️ <b>HPA:</b> {{ printf "%s\n" .Labels.horizontalpodautoscaler }}{{ end }}
          {{- if .Labels.integration }}🔌 <b>Integration:</b> {{ printf "%s\n" .Labels.integration }}{{ end }}
          {{- if .Labels.image }}🐳 <b>Image:</b> {{ printf "%s\n" .Labels.image }}{{ end }}
          {{- if .Labels.reason }}❓ <b>Reason:</b> {{ printf "%s\n" .Labels.reason }}{{ end }}
          {{ end }}

    # Telegram Receiver for Pod lifecycle events
    - name: WL-PODS-condition
      telegram_configs:
      - send_resolved: false  # Don't send resolved for pod events
        bot_token_file: "/etc/secrets/telegram/bot-token"
        chat_id: -5079754285
        api_url: "https://api.telegram.org"
        parse_mode: HTML
        message: |
          {{ range .Alerts }}
          {{ if eq .Labels.podstat "startpod"}}🚀 <b>POD STARTED</b>{{ else if eq .Labels.podstat "stoppod"}}🛑 <b>POD STOPPED</b>{{ else }}📊 <b>{{ .Labels.podstat | toUpper }}</b>{{ end }}
          {{ printf "⏰ Time: %s\n" (.StartsAt.Format "2006-01-02 15:04:05 MST") }}

          {{- if .Annotations.summary }}📋 <b>Summary:</b> {{ printf "%s\n" .Annotations.summary }}{{ end }}
          {{- if .Annotations.description }}📝 <b>Description:</b> {{ printf "%s\n" .Annotations.description }}{{ end }}
          {{- if .Labels.namespace }}🏷 <b>Namespace:</b> {{ printf "%s\n" .Labels.namespace }}{{ end }}
          {{- if .Labels.exported_namespace }}🏷 <b>Namespace:</b> {{ printf "%s\n" .Labels.exported_namespace }}{{ end }}
          {{- if .Labels.pod }}📦 <b>Pod:</b> {{ printf "%s\n" .Labels.pod }}{{ end }}
          {{- if .Labels.exported_pod }}📦 <b>Pod:</b> {{ printf "%s\n" .Labels.exported_pod }}{{ end }}
          {{- if .Labels.deployment }}🚀 <b>Deployment:</b> {{ printf "%s\n" .Labels.deployment }}{{ end }}
          {{- if .Labels.container }}📦 <b>Container:</b> {{ printf "%s\n" .Labels.container }}{{ end }}
          {{- if .Labels.node }}🖥 <b>Node:</b> {{ printf "%s\n" .Labels.node }}{{ end }}
          {{- if .Labels.image }}🐳 <b>Image:</b> {{ printf "%s\n" .Labels.image }}{{ end }}
          {{- if .Labels.reason }}❓ <b>Reason:</b> {{ printf "%s\n" .Labels.reason }}{{ end }}
          {{ end }}

    # Null receiver for suppressed alerts
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

