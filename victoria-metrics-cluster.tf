resource "helm_release" "victoria_metrics_cluster" {
  name       = "vm-cluster"
  repository = "https://victoriametrics.github.io/helm-charts/"
  chart      = "victoria-metrics-cluster"
  namespace  = "monitoring"
  #create_namespace = true
  version = "0.30.1" # Замените на актуальную версию
  timeout = "300"

  values = [
    <<-EOT
# --- vmstorage ---
vmstorage:
  replicaCount: 3
  extraArgs:
    memory.allowedPercent: "80"
    dedup.minScrapeInterval: "30s"
    search.maxUniqueTimeseries: "10000000"
    retentionPeriod: "33d"
    storage.minFreeDiskSpaceBytes: "1073741824" # <-- (1GB)
    envflag.enable: "true"
    envflag.prefix: VM_
    loggerFormat: json
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchExpressions:
              - key: app
                operator: In
                values:
                  - vmstorage
          topologyKey: "kubernetes.io/hostname"
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchExpressions:
                - key: app
                  operator: In
                  values:
                    - vmstorage
            topologyKey: "topology.kubernetes.io/zone"
  nodeSelector:
    "eks-cluster/nodegroup": "${data.terraform_remote_state.eks_core.outputs.cluster-name}-victoria"
  resources:
    requests:
      cpu: "500m"
      memory: "3Gi"
    limits:
      cpu: "1000m"
      memory: "3Gi"
  persistentVolume:
    enabled: true
    accessModes:
      - ReadWriteOnce
    storageClassName: "ebs-sc-retain"
    size: 50Gi

# --- vmselect ---
vmselect:
  replicaCount: 2
  extraArgs:
    dedup.minScrapeInterval: "30s"
    search.treatDotsAsIsInRegexps: "false"
    search.logSlowQueryDuration: "10s"
    search.noStaleMarkers: "true"
    search.maxQueryLen: "65536"
    memory.allowedPercent: "80"
    search.maxUniqueTimeseries: "500000"
    search.maxSamplesPerQuery: "40000000"
    search.maxQueueDuration: "10s"
    search.maxConcurrentRequests: "20"
    envflag.enable: "true"
    envflag.prefix: VM_
    loggerFormat: json
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: app
                operator: In
                values:
                  - vmselect
          topologyKey: kubernetes.io/hostname
  nodeSelector:
    "eks-cluster/nodegroup": "${data.terraform_remote_state.eks_core.outputs.cluster-name}-victoria"
  resources:
    requests:
      cpu: "1000m"
      memory: "1Gi"
    limits:
      cpu: "1500m"
      memory: "2Gi"

# --- vminsert ---
vminsert:
  replicaCount: 2
  extraArgs:
    replicationFactor: "3"
    disableRerouting: "true"
    envflag.enable: "true"
    envflag.prefix: VM_
    loggerFormat: json
    maxLabelsPerTimeseries: "30"  # safe cardinality explosion
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: app
                operator: In
                values:
                  - vminsert
          topologyKey: kubernetes.io/hostname
  nodeSelector:
    "eks-cluster/nodegroup": "${data.terraform_remote_state.eks_core.outputs.cluster-name}-victoria"
  resources:
    requests:
      cpu: "200m"
      memory: "1Gi"
    limits:
      cpu: "500m"
      memory: "1500Mi"
EOT
  ]
}
