# rbac-generic/main.tf

locals {
  # Convert the list to a map for easier use in for_each (key is the index)
  rbac_configs_map = { for idx, cfg in var.rbac_configs : idx => cfg }

  # Filter configurations for creating Role/RoleBinding (namespaced)
  namespaced_configs = {
    for idx, cfg in local.rbac_configs_map : idx => cfg if !lookup(cfg, "cluster_wide", false)
  }

  # Filter configurations for creating ClusterRole/ClusterRoleBinding (cluster-wide)
  cluster_configs = {
    for idx, cfg in local.rbac_configs_map : idx => cfg if lookup(cfg, "cluster_wide", false)
  }

  # Filter configurations for which the ServiceAccount needs to be created
  configs_to_create_sa = {
    for idx, cfg in local.rbac_configs_map : idx => cfg if lookup(cfg, "create_service_account", false)
  }
}

# --- ServiceAccount Creation (Conditional) ---

resource "kubernetes_service_account" "managed_sa" {
  # Create only for configurations with create_service_account = true
  for_each = local.configs_to_create_sa

  metadata {
    name      = each.value.service_account_name
    namespace = each.value.namespace
    # labels      = lookup(each.value, "service_account_labels", {})
    # annotations = lookup(each.value, "service_account_annotations", {})
  }

  # automount_service_account_token = lookup(each.value, "service_account_automount_token", null)
}


# --- Resources for Namespaced Role and RoleBinding ---

resource "kubernetes_role" "namespaced_role" {
  # Create only for configurations with cluster_wide = false
  for_each = local.namespaced_configs

  metadata {
    # Name: prefix-namespace
    name = "${var.role_name_prefix}-${each.value.namespace}"
    # Role is always bound to a namespace
    namespace = each.value.namespace
  }

  # Dynamically create rules from the configuration
  dynamic "rule" {
    for_each = each.value.rules
    content {
      api_groups = rule.value.api_groups
      resources  = rule.value.resources
      verbs      = rule.value.verbs
    }
  }
}

resource "kubernetes_role_binding" "namespaced_binding" {
  # Create only for configurations with cluster_wide = false
  for_each = local.namespaced_configs

  metadata {
    # Name: prefix-binding-namespace
    name = "${var.role_name_prefix}-binding-${each.value.namespace}"
    # RoleBinding is also bound to a namespace
    namespace = each.value.namespace
  }

  # Specify the ServiceAccount to which the role is applied
  subject {
    kind = "ServiceAccount"
    name = each.value.service_account_name
    # The ServiceAccount's namespace must match the RoleBinding's namespace
    namespace = each.value.namespace
  }

  # Reference the created Role
  role_ref {
    kind = "Role" # Binding to a Role
    # CORRECTED: Access metadata[0].name
    name      = kubernetes_role.namespaced_role[each.key].metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }

  # Depend on the entire set of managed ServiceAccounts.
  depends_on = [
    kubernetes_service_account.managed_sa
  ]
}

# --- Resources for ClusterRole and ClusterRoleBinding ---

resource "kubernetes_cluster_role" "cluster_scope_role" {
  # Create only for configurations with cluster_wide = true
  for_each = local.cluster_configs

  metadata {
    # Name must be unique cluster-wide. Use prefix and namespace from config for context/uniqueness
    name = "${var.role_name_prefix}-cluster-${each.value.namespace}-${each.value.service_account_name}"
    # ClusterRole does not have metadata.namespace
  }

  # Dynamically create rules from the configuration
  dynamic "rule" {
    for_each = each.value.rules
    content {
      api_groups = rule.value.api_groups
      resources  = rule.value.resources
      verbs      = rule.value.verbs
    }
  }
}

resource "kubernetes_cluster_role_binding" "cluster_scope_binding" {
  # Create only for configurations with cluster_wide = true
  for_each = local.cluster_configs

  metadata {
    # Name must be unique cluster-wide
    name = "${var.role_name_prefix}-clusterbinding-${each.value.namespace}-${each.value.service_account_name}"
    # ClusterRoleBinding does not have metadata.namespace
  }

  # Specify the ServiceAccount to which the cluster role is applied
  subject {
    kind = "ServiceAccount"
    name = each.value.service_account_name
    # !!! Important: Specify the namespace for the ServiceAccount
    namespace = each.value.namespace
  }

  # Reference the created ClusterRole
  role_ref {
    kind = "ClusterRole" # Binding to a ClusterRole
    # CORRECTED: Access metadata[0].name
    name      = kubernetes_cluster_role.cluster_scope_role[each.key].metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }

  # Depend on the entire set of managed ServiceAccounts.
  depends_on = [
    kubernetes_service_account.managed_sa
  ]
}
