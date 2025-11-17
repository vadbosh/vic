# rbac-generic/variables.tf

variable "role_name_prefix" {
  description = "Prefix for the names of the created Roles/ClusterRoles and RoleBindings/ClusterRoleBindings."
  type        = string
  default     = "custom-rbac" # You can change the default prefix
}

variable "rbac_configs" {
  description = "A list of RBAC configurations. Each configuration defines rules, a service account, and optionally a namespace, scope (cluster-wide or namespaced), and whether to create the service account."
  type = list(object({
    # Namespace: Required for Role/RoleBinding. For ClusterRoleBinding, it specifies the ServiceAccount's namespace.
    namespace = string
    # The name of the ServiceAccount to which the permissions are applied.
    service_account_name = string
    # Flag: true to create ClusterRole/ClusterRoleBinding, false (default) for Role/RoleBinding.
    cluster_wide = optional(bool, false)
    # Flag: true to create the ServiceAccount if it doesn't exist, false (default) to use an existing one.
    create_service_account = optional(bool, false)
    # List of RBAC rules applied by the role.
    rules = list(object({
      api_groups = list(string)
      resources  = list(string)
      verbs      = list(string)
    }))
    # Optional fields can be added here to configure the created SA, for example:
    # service_account_automount_token = optional(bool, null)
    # service_account_annotations = optional(map(string), {})
    # service_account_labels = optional(map(string), {})
  }))
  default = [] # The list of configurations is empty by default

  # --- Validations ---
  validation {
    # Each configuration must contain at least one rule
    condition     = alltrue([for config in var.rbac_configs : length(config.rules) > 0])
    error_message = "Each RBAC configuration must contain at least one rule definition in 'rules'."
  }

  validation {
    # Each rule must contain the required fields
    condition = alltrue([
      for config in var.rbac_configs : alltrue([
        for rule in config.rules : rule.api_groups != null && rule.resources != null && rule.verbs != null
      ])
    ])
    error_message = "Each rule within 'rules' must specify 'api_groups', 'resources', and 'verbs'."
  }

  validation {
    # If create_service_account=true, then namespace and service_account_name must be specified
    condition = alltrue([
      for cfg in var.rbac_configs :
      !lookup(cfg, "create_service_account", false) || (cfg.namespace != null && cfg.service_account_name != null)
    ])
    error_message = "If 'create_service_account' is true, 'namespace' and 'service_account_name' must be specified for that configuration."
  }

  validation {
    # service_account_name cannot be empty
    condition = alltrue([
      for cfg in var.rbac_configs : cfg.service_account_name != "" && cfg.service_account_name != null
    ])
    error_message = "The 'service_account_name' cannot be empty or null."
  }

  validation {
    # namespace cannot be empty
    condition = alltrue([
      for cfg in var.rbac_configs : cfg.namespace != "" && cfg.namespace != null
    ])
    error_message = "The 'namespace' cannot be empty or null."
  }
}
