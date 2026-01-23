resource "kubernetes_manifest" "keda_scaled_object_php_app" {
  manifest = {
    apiVersion = "keda.sh/v1alpha1"
    kind       = "ScaledObject"
    metadata = {
      name      = format("%s-%s", "app-scaledobject", var.app_name)
      namespace = var.deploy_env
    }
    spec = {
      scaleTargetRef = {
        name = var.app_name
      }
      minReplicaCount = var.minReplicas
      maxReplicaCount = var.maxReplicas
      pollingInterval = 30
      cooldownPeriod  = 180

      triggers = [
        {
          type       = "cpu"
          metricType = "Utilization"
          metadata   = { value = "${var.cpu_threshold}" }
        },
        {
          type = "prometheus"
          metadata = {
            serverAddress = "http://vm-cluster-victoria-metrics-cluster-vmselect.monitoring.svc.cluster.local:8481/select/0/prometheus"
            threshold     = "${var.prometheus_threshold}"
            query         = <<-EOT
              sum(phpfpm_active_processes{namespace="${var.deploy_env}",pod=~"${var.app_name}-.*"}) / 
              (kube_deployment_status_replicas_ready{deployment="${var.app_name}"} * ${var.php_fpm_max_proc} * 0.85)
            EOT
          }
        }
      ]
    }
  }
  depends_on = [helm_release.app]
}
