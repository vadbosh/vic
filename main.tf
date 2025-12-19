locals {
  # Уникальное имя приложения
  app_name = "sail"

  # Путь к папке с правилами именно этого приложения
  # Предполагаем, что yaml файлы лежат рядом в папке alert-rules
  rules_dir = "${path.module}/alert-rules"
}

resource "kubernetes_config_map_v1" "sail_alert_rules" {
  metadata {
    # 1. Уникальное имя ConfigMap.
    # Оно должно отличаться от Payment app, иначе Terraform перезапишет его.
    name = "vmalert-rules-app2-${local.app_name}"

    # 2. Тот же Namespace, где установлен VictoriaMetrics Alert
    namespace = "monitoring"

    labels = {
      # === ГЛАВНЫЙ ТРИГГЕР ===
      # Именно по этой метке Sidecar найдет этот ConfigMap
      "alert_part_of" = "vm-alert-apps"

      # Дополнительные метки для удобства (не влияют на sidecar)
      "app"        = local.app_name
      "managed-by" = "terraform-sail-repo"
    }
  }

  data = {
    # Читаем все .yaml файлы из папки alert-rules текущего модуля
    for file in try(fileset(local.rules_dir, "*.yaml"), []) :
    file => file("${local.rules_dir}/${file}")
  }
}
