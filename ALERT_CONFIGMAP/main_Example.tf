module "auth_alerts" {
  source                = "./modules/alert_configmap" # path to the folder with files above (module)
  app_name              = "auth-service"
  unique_name_configmap = "auth-service-alerts"
  namespace             = "monitoring"
  rules_dir             = "${path.module}/alert-rules"

  labels = {
    # !!! Labels to apply to the ConfigMap. Must include the sidecar trigger label.
    "alert_part_of" = "vm-alert-apps"
  }
}
