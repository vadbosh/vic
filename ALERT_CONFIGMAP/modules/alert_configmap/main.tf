resource "kubernetes_config_map_v1" "alert_rules" {
  metadata {
    name      = var.unique_name_configmap
    namespace = var.namespace

    # Merging mandatory trigger label with optional app-specific labels
    labels = merge(
      {
        "app.kubernetes.io/managed-by" = "terraform"
        "app.kubernetes.io/instance"   = var.app_name
        "app"                          = var.app_name
      },
      var.labels
    )
  }

  # Dynamically load all yaml files from the specified directory
  data = {
    for file in try(fileset(var.rules_dir, "*.yaml"), []) :
    file => file("${var.rules_dir}/${file}")
  }
}
