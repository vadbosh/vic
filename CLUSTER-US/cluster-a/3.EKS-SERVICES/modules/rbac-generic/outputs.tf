# rbac-generic/outputs.tf

output "role_and_clusterrole_names" {
  description = "Names of all created Roles and ClusterRoles."
  value = concat(
    # CORRECTED: Access metadata[0].name
    [for role in kubernetes_role.namespaced_role : role.metadata[0].name],
    # CORRECTED: Access metadata[0].name
    [for role in kubernetes_cluster_role.cluster_scope_role : role.metadata[0].name]
  )
}

output "binding_and_clusterbinding_names" {
  description = "Names of all created RoleBindings and ClusterRoleBindings."
  value = concat(
    # CORRECTED: Access metadata[0].name
    [for binding in kubernetes_role_binding.namespaced_binding : binding.metadata[0].name],
    # CORRECTED: Access metadata[0].name
    [for binding in kubernetes_cluster_role_binding.cluster_scope_binding : binding.metadata[0].name]
  )
}

output "created_service_account_names_with_namespace" {
  description = "Map of ServiceAccounts created by this module, mapping name to namespace."
  value = {
    # CORRECTED: Access metadata[0].name and metadata[0].namespace
    for sa in kubernetes_service_account.managed_sa : sa.metadata[0].name => sa.metadata[0].namespace
  }
}

output "created_service_account_names" {
  description = "List of names of the ServiceAccounts created by this module (if any)."
  value = [
    # CORRECTED: Access metadata[0].name
    for sa in kubernetes_service_account.managed_sa : sa.metadata[0].name
  ]
}

# Optional: Output the full object of the created SA if needed
# output "created_service_accounts" {
#   description = "Full objects of the ServiceAccounts created by this module."
#   value       = kubernetes_service_account.managed_sa
#   sensitive   = true # If the SA might contain sensitive info in annotations/etc
# }
