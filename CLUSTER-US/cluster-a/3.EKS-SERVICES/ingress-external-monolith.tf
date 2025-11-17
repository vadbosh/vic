
module "external_ingress_nginx_version" {
  source             = "./modules/helm-version"
  chart_name         = var.ingress_external_config.chart_name
  versions_file_path = "${path.root}/helm_versions.json"
}

resource "helm_release" "external_ingress_nginx" {
  count            = module.external_ingress_nginx_version.version != null ? 1 : 0
  name             = var.ingress_external_config.helm_release_name
  namespace        = var.ingress_external_config.namespace
  wait             = true
  create_namespace = true
  chart            = var.ingress_external_config.chart_name
  repository       = "https://kubernetes.github.io/ingress-nginx"
  version          = module.external_ingress_nginx_version.version
  timeout          = "300"
  depends_on       = [helm_release.reloader, helm_release.aws-load-balancer-controller]
  values = [
    <<-EOF
controller:
  annotations:
    reloader.stakater.com/auto: "true"
  ingressClass: ${var.ingress_external_config.class_name}
  ingressClassResource:
    name: ${var.ingress_external_config.class_name}
    controllerValue: "k8s.io/${local.ingress_controller.external_nginx}"
    enabled: true
  resources:
    #limits:
    # cpu: 900m
    # memory: 512Mi
    requests:
      cpu: 400m
      memory: 256Mi
#  extraVolumeMounts:
#    - name: global-functions
#      mountPath: /etc/nginx/lua/global-functions/
#      readOnly: true
#    - name: custom-config-conf
#      mountPath: /etc/nginx/lua/custom-config
#      readOnly: true
#  extraVolumes:
#    - name: global-functions
#      configMap:
#        name: global-functions
#    - name: custom-config-conf
#      configMap:
#        name: custom-config-conf
  config:
    custom-http-errors: >-
      400,401,403,404,408,429,500,502,503,504,507
    allow-snippet-annotations: "true" # !!! LUA
    annotations-risk-level: "Critical" # !!! LUA
    lua-shared-dicts: "configuration_data:10M" # !!! LUA
    load-balance: "ewma" 
    #use-http2: "false"
    enable-brotli: "true"
    brotli-level: "5"
    use-gzip: "true"
    gzip-level: "5"
    compute-full-forwarded-for: "true"
    use-forwarded-headers: "true"
    proxy-body-size: "1024m"
    proxy-buffer-size: "64k"
    proxy-connect-timeout: 180
    proxy-read-timeout: 180
    proxy-send-timeout: 180
    proxy-buffer-size: "64k"
    proxy-real-ip-cidr: "${data.terraform_remote_state.network.outputs.cluster_top_cidr}"
    client-header-buffer-size: "256k"
    client-body-buffer-size: "256k"
    client-header-timeout: 120
    client-body-timeout: 120
    large-client-header-buffers: "16 64k"
    http2-max-header-size: "64k"
    upstream-keepalive-timeout: 180
    keep-alive: 180
    forwarded-for-header: "X-Forwarded-For"
    enable-real-ip: "true"
    use-proxy-protocol: "true"
    http-snippet: |
      more_set_headers "Server: WL-${local.ingress_2lb_name.external_nginx}";
    log-format-upstream: '$remote_addr "$http_x_forwarded_for" - [$time_iso8601] STATUS=$status "$service_name" "$request" "$http_user_agent" $body_bytes_sent request_time=$request_time upstream_status=$upstream_status upstream_response_time=$upstream_response_time upstream_connect_time=$upstream_connect_time upstream_header_time=$upstream_header_time $scheme host=$http_host'
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: release
              operator: In
              values:
              - ${local.ingress_controller.external_nginx}
          topologyKey: kubernetes.io/hostname
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: "eks-cluster/nodegroup"
            operator: In
            values: ["${local.ingress_nodegroup.ingress}"]
  replicaCount: 1
  autoscaling:
    enabled: true
    minReplicas: 1
    maxReplicas: 8
    targetCPUUtilizationPercentage: 90
    targetMemoryUtilizationPercentage: 90
  service:
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-security-groups: "${local.ingress_security_group_ids.external_nginx}"
      service.beta.kubernetes.io/aws-load-balancer-manage-backend-security-group-rules: 'true' 
      service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
      service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
      service.beta.kubernetes.io/aws-load-balancer-name: "${local.ingress_2lb_name.external_nginx}"
      service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags: "Name=${local.ingress_2lb_name.external_nginx}"
      service.beta.kubernetes.io/aws-load-balancer-subnets: "${join(",", data.terraform_remote_state.network.outputs.public_subnet_ids)}"
      service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
      service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: "proxy_protocol_v2.enabled=true,preserve_client_ip.enabled=true"
      service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout: '180'
      service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: 'true'
    externalTrafficPolicy: "Cluster"
    type: LoadBalancer
  metrics:
    enabled: false
defaultBackend:
  enabled: true
  replicaCount: 1
  resources:
   #limits:
     #cpu: 900m
     #memory: 512Mi
    requests:
      cpu: 400m
      memory: 256Mi
  autoscaling:
    enabled: true
    minReplicas: 1
    maxReplicas: 8
    targetCPUUtilizationPercentage: 90
    targetMemoryUtilizationPercentage: 90
  extraEnvs:
  - name: PROXY_URL
    value: ${local.default_proxy_url.ingress}
  image:
    image:
    registry: "public.ecr.aws/wellnessliving"
    image: nginx2downpage
    tag: latest
    port: 8080
    pullPolicy: Always
    readOnlyRootFilesystem: false    
  nodeSelector:
    eks-cluster/nodegroup: "${local.ingress_nodegroup.ingress}"
EOF
  ]
}
