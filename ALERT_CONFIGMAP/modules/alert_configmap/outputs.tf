output "configmap_name" {
  description = "The name of the created ConfigMap"
  value       = kubernetes_config_map_v1.alert_rules.metadata[0].name
}

output "configmap_id" {
  description = "The ID of the created ConfigMap"
  value       = kubernetes_config_map_v1.alert_rules.id
}
