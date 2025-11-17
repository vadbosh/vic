<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_cluster_role.cluster_scope_role](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role) | resource |
| [kubernetes_cluster_role_binding.cluster_scope_binding](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_binding) | resource |
| [kubernetes_role.namespaced_role](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role) | resource |
| [kubernetes_role_binding.namespaced_binding](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding) | resource |
| [kubernetes_service_account.managed_sa](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_rbac_configs"></a> [rbac\_configs](#input\_rbac\_configs) | A list of RBAC configurations. Each configuration defines rules, a service account, and optionally a namespace, scope (cluster-wide or namespaced), and whether to create the service account. | <pre>list(object({<br/>    # Namespace: Required for Role/RoleBinding. For ClusterRoleBinding, it specifies the ServiceAccount's namespace.<br/>    namespace = string<br/>    # The name of the ServiceAccount to which the permissions are applied.<br/>    service_account_name = string<br/>    # Flag: true to create ClusterRole/ClusterRoleBinding, false (default) for Role/RoleBinding.<br/>    cluster_wide = optional(bool, false)<br/>    # Flag: true to create the ServiceAccount if it doesn't exist, false (default) to use an existing one.<br/>    create_service_account = optional(bool, false)<br/>    # List of RBAC rules applied by the role.<br/>    rules = list(object({<br/>      api_groups = list(string)<br/>      resources  = list(string)<br/>      verbs      = list(string)<br/>    }))<br/>    # Optional fields can be added here to configure the created SA, for example:<br/>    # service_account_automount_token = optional(bool, null)<br/>    # service_account_annotations = optional(map(string), {})<br/>    # service_account_labels = optional(map(string), {})<br/>  }))</pre> | `[]` | no |
| <a name="input_role_name_prefix"></a> [role\_name\_prefix](#input\_role\_name\_prefix) | Prefix for the names of the created Roles/ClusterRoles and RoleBindings/ClusterRoleBindings. | `string` | `"custom-rbac"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_binding_and_clusterbinding_names"></a> [binding\_and\_clusterbinding\_names](#output\_binding\_and\_clusterbinding\_names) | Names of all created RoleBindings and ClusterRoleBindings. |
| <a name="output_created_service_account_names"></a> [created\_service\_account\_names](#output\_created\_service\_account\_names) | List of names of the ServiceAccounts created by this module (if any). |
| <a name="output_created_service_account_names_with_namespace"></a> [created\_service\_account\_names\_with\_namespace](#output\_created\_service\_account\_names\_with\_namespace) | Map of ServiceAccounts created by this module, mapping name to namespace. |
| <a name="output_role_and_clusterrole_names"></a> [role\_and\_clusterrole\_names](#output\_role\_and\_clusterrole\_names) | Names of all created Roles and ClusterRoles. |
<!-- END_TF_DOCS -->