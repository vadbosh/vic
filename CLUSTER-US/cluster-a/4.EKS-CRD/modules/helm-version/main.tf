locals {
  versions = jsondecode(file(var.versions_file_path))
}

output "version" {
  value       = lookup(local.versions, var.chart_name, null)
  description = "The version of the specified chart, or null if not found."
}
