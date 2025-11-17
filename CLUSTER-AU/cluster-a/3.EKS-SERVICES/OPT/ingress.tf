locals {
  public_subnets  = join(",", data.aws_subnets.public.ids)
  private_subnets = join(",", data.aws_subnets.private.ids)
}

resource "helm_release" "ingress_nginx_demo" {

  name             = "ingress-nginx"
  namespace        = "ingress-nginx"
  wait             = true
  create_namespace = true
  chart            = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  version          = "4.12.0"
  timeout          = "30"

  #  depends_on = [
  #  module.sg_main_nlb.security_group_id,
  #]


  values = [
    <<-EOF
controller:
  annotations:
    reloader.stakater.com/auto: "true"
  ingressClass: nginx
  ingressClassResource:
    name: nginx
    controllerValue: "k8s.io/ingress-nginx"
    enabled: true
  resources:
    limits:
      cpu: 900m
      memory: 512Mi
    requests:
      cpu: 400m
      memory: 256Mi
  extraVolumeMounts:
    - name: global-functions
      mountPath: /etc/nginx/lua/global-functions/
      readOnly: true
    - name: custom-config-conf
      mountPath: /etc/nginx/lua/custom-config
      readOnly: true  
  extraVolumes:
    - name: global-functions
      configMap:
        name: global-functions
    - name: custom-config-conf
      configMap:
        name: custom-config-conf
  config:
    allow-snippet-annotations: "true"
    annotations-risk-level: "Critical"
    load-balance: "ewma"
    lua-shared-dicts: "configuration_data:5M"
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
    proxy-real-ip-cidr: "10.4.0.0/16"
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
      map $uri $path_type {
          ~*^/(explore|_next)/ explore;
          ~*^/explore$  explore2;
          ~*^/yoga(/.*)?$      yoga;
          default             default;
      }
    log-format-upstream: '$remote_addr "$http_x_forwarded_for" - [$time_iso8601] STATUS=$status "$service_name" "$request" "$http_user_agent" $body_bytes_sent upstream_status=$upstream_status request_time=$request_time upstream_response_time=$upstream_response_time upstream_connect_time=$upstream_connect_time upstream_header_time=$upstream_header_time $scheme host=$http_host'
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
              - ingress-nginx
          topologyKey: kubernetes.io/hostname
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: "eks-cluster/nodegroup"
            operator: In
            values: ["thoth-sandbox-ingress"]
  replicaCount: 1
  autoscaling:
    enabled: true
    minReplicas: 1
    maxReplicas: 8
    targetCPUUtilizationPercentage: 90
    targetMemoryUtilizationPercentage: 90
  service:
    annotations:
      # service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
      # service.beta.kubernetes.io/aws-load-balancer-type: "external"
      # service.beta.kubernetes.io/aws-load-balancer-subnets: "${local.public_subnets}"
      service.beta.kubernetes.io/aws-load-balancer-scheme: "internal"
      service.beta.kubernetes.io/aws-load-balancer-internal: "true"
      service.beta.kubernetes.io/aws-load-balancer-subnets: "${local.private_subnets}"
      service.beta.kubernetes.io/aws-load-balancer-type: nlb
      service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
      service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "instance"
      #service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
      service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: "proxy_protocol_v2.enabled=true"
      service.beta.kubernetes.io/aws-load-balancer-backend-protocol: tcp
      service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout: '180'
      service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: 'true'
      service.beta.kubernetes.io/aws-load-balancer-name: thoth-sandbox-ingress
      service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags: |
        Environment=thoth-sandbox
    externalTrafficPolicy: "Cluster"
    type: LoadBalancer
  metrics:
    enabled: false
    serviceMonitor:
      enabled: false # !!!
      additionalLabels: { "release": "monitoring", }
      namespace: "ingress-nginx"
defaultBackend:
  enabled: false 
  extraEnvs:
  - name: TEMPLATE_NAME
    value: ghost
  - name: SHOW_DETAILS
    value: 'true'
  image:
    registry: "docker.io/tarampampam"
    image: error-pages
    tag: 3.3
    port: 8080
    #registry: "docker.io/mendhak"
    #image: http-https-echo
    #tag: 23
    #port: 8080
    #runAsNonRoot: false
    #runAsUser: 0
    #runAsGroup: 0
    #allowPrivilegeEscalation: true
    readOnlyRootFilesystem: false
    #seccompProfile:
    #  type: Unconfined
  nodeSelector:
    eks-cluster/nodegroup: thoth-sandbox-ingress
EOF
  ]
}
