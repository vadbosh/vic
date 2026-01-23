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
| [kubernetes_config_map_v1.alert_rules](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | Name of the application these rules belong to | `string` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels to apply to the ConfigMap. Must include the sidecar trigger label. | `map(string)` | <pre>{<br/>  "alert_part_of": "vm-alert-apps"<br/>}</pre> | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace where the ConfigMap will be created | `string` | n/a | yes |
| <a name="input_rules_dir"></a> [rules\_dir](#input\_rules\_dir) | Path to the directory containing .yaml or .yml alert rule files | `string` | n/a | yes |
| <a name="input_unique_name_configmap"></a> [unique\_name\_configmap](#input\_unique\_name\_configmap) | Unique name for the ConfigMap | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_configmap_id"></a> [configmap\_id](#output\_configmap\_id) | The ID of the created ConfigMap |
| <a name="output_configmap_name"></a> [configmap\_name](#output\_configmap\_name) | The name of the created ConfigMap |
<!-- END_TF_DOCS -->