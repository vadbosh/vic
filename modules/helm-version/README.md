<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | The name of the chart (key in the JSON file) to get the version for. | `string` | n/a | yes |
| <a name="input_versions_file_path"></a> [versions\_file\_path](#input\_versions\_file\_path) | The absolute path to the JSON file containing chart versions. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_version"></a> [version](#output\_version) | The version of the specified chart, or null if not found. |
<!-- END_TF_DOCS -->