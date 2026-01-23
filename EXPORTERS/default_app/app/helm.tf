# helm plugin install https://github.com/hypnoglow/helm-s3.git
# helm repo add universal-chart s3://wl-helm-charts/k8s-aws-demo/


data "template_file" "helm_values" {
  template = file("./values.template.yaml")
  vars = {
    replicas                     = var.replicas
    app_name                     = var.app_name
    repository_name              = var.repository_name
    ecr                          = var.ecr
    deploy_env                   = var.deploy_env
    image_tag                    = var.image_tag
    nodepool                     = var.nodepool
    app_domain                   = var.app_domain
    health_check                 = var.health_check
    app_port                     = var.app_port
    resource_limit_cpu           = var.resource_limit_cpu
    resource_limit_memory        = var.resource_limit_memory
    resource_request_cpu         = var.resource_request_cpu
    resource_request_memory      = var.resource_request_memory
    PDB_minAvailable             = var.PDB_minAvailable
    entrypoint                   = var.entrypoint
    rollingUpdate_maxSurge       = var.rollingUpdate_maxSurge
    rollingUpdate_maxUnavailable = var.rollingUpdate_maxUnavailable
    minReplicas                  = var.minReplicas
    maxReplicas                  = var.maxReplicas
    container_init_delay         = var.container_init_delay
    ingress_class_name           = var.ingress_class_name
    tls_secret_name              = var.tls_secret_name
    #
    php_fpm_max_proc     = var.php_fpm_max_proc
    fpm_metrics_port     = var.fpm_metrics_port
    apache_metrics_port  = var.apache_metrics_port
    cpu_threshold        = var.cpu_threshold
    prometheus_threshold = var.prometheus_threshold
  }
}

output "rendered" {
  value = data.template_file.helm_values.rendered
}

output "app_name" {
  value = data.template_file.helm_values.vars.app_name
}

resource "helm_release" "app" {
  repository        = "s3://wl-helm-charts/k8s-aws-demo/"
  chart             = "universal-chart"
  version           = var.chart_version
  name              = var.app_name
  namespace         = var.deploy_env
  wait              = true
  dependency_update = true
  max_history       = 5
  timeout           = var.helm_run_timeout
  values            = [data.template_file.helm_values.rendered]
}

