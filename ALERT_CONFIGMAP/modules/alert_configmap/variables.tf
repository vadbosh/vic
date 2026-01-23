variable "app_name" {
  description = "Name of the application these rules belong to"
  type        = string
}

variable "rules_dir" {
  description = "Path to the directory containing .yaml or .yml alert rule files"
  type        = string
}

variable "unique_name_configmap" {
  description = "Unique name for the ConfigMap"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace where the ConfigMap will be created"
  type        = string
}

variable "labels" {
  description = "Labels to apply to the ConfigMap. Must include the sidecar trigger label."
  type        = map(string)
  default = {
    "alert_part_of" = "vm-alert-apps"
  }
}
