
deploy_env                   = "default"
replicas                     = "1"
ecr                          = "381142409470.dkr.ecr.us-east-1.amazonaws.com"
nodepool                     = "thoth-sandbox-xlarge"
health_check                 = "/"
app_port                     = 80
app_domain                   = "mmm.wellnessliving.com"
resource_limit_cpu           = "500m"
resource_limit_memory        = "300Mi"
resource_request_cpu         = "500m"
resource_request_memory      = "300Mi"
minReplicas                  = "1"
maxReplicas                  = "4"
container_init_delay         = "10"
ingress_class_name           = "shared-victoria"
helm_run_timeout             = "240"
PDB_minAvailable             = "0"
rollingUpdate_maxSurge       = "1"
rollingUpdate_maxUnavailable = "100%"
entrypoint                   = "debug"
tls_secret_name              = "wellnessliving-com"
# metrics part
php_fpm_max_proc     = "4"
fpm_metrics_port     = "9253"
apache_metrics_port  = "9117"
cpu_threshold        = "80"
prometheus_threshold = "1.0"




