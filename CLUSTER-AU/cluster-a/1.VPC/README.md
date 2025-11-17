<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_acme"></a> [acme](#requirement\_acme) | 2.35.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.10.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | 3.0.2 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.38.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.5.3 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.7.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.10.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.2 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_subnets"></a> [subnets](#module\_subnets) | cloudposse/dynamic-subnets/aws | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_key_pair.ssh_key_pair](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_security_group.externally_managed_rules_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_ipv4_cidr_block_association.cluster_sandbox_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_ipv4_cidr_block_association) | resource |
| [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_internet_gateway.igtws](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/internet_gateway) | data source |
| [aws_nat_gateways.ngws](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/nat_gateways) | data source |
| [aws_vpcs.net_workspace](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpcs) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_internet_gateway_tag_name"></a> [aws\_internet\_gateway\_tag\_name](#input\_aws\_internet\_gateway\_tag\_name) | n/a | `string` | n/a | yes |
| <a name="input_aws_vpcs_tag_name"></a> [aws\_vpcs\_tag\_name](#input\_aws\_vpcs\_tag\_name) | n/a | `string` | n/a | yes |
| <a name="input_cidr_create"></a> [cidr\_create](#input\_cidr\_create) | n/a | `bool` | n/a | yes |
| <a name="input_cluster-name"></a> [cluster-name](#input\_cluster-name) | The name of the EKS Cluster | `string` | n/a | yes |
| <a name="input_ingress_ports"></a> [ingress\_ports](#input\_ingress\_ports) | TCP Ingess SG default ports | `list(number)` | <pre>[<br/>  80,<br/>  443<br/>]</pre> | no |
| <a name="input_k8s_cidr_block_associations"></a> [k8s\_cidr\_block\_associations](#input\_k8s\_cidr\_block\_associations) | n/a | `string` | n/a | yes |
| <a name="input_max_nats"></a> [max\_nats](#input\_max\_nats) | n/a | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The name of the AWS Region | `string` | n/a | yes |
| <a name="input_security_group_names"></a> [security\_group\_names](#input\_security\_group\_names) | List of names for the Security Groups to be created | `list(string)` | n/a | yes |
| <a name="input_ssh_key_pair_name"></a> [ssh\_key\_pair\_name](#input\_ssh\_key\_pair\_name) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster-name"></a> [cluster-name](#output\_cluster-name) | n/a |
| <a name="output_cluster_top_cidr"></a> [cluster\_top\_cidr](#output\_cluster\_top\_cidr) | n/a |
| <a name="output_igt_id"></a> [igt\_id](#output\_igt\_id) | n/a |
| <a name="output_key_name"></a> [key\_name](#output\_key\_name) | n/a |
| <a name="output_nat_id"></a> [nat\_id](#output\_nat\_id) | n/a |
| <a name="output_private_subnet_cidrs"></a> [private\_subnet\_cidrs](#output\_private\_subnet\_cidrs) | n/a |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | n/a |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | n/a |
| <a name="output_region"></a> [region](#output\_region) | n/a |
| <a name="output_security_group_id_map"></a> [security\_group\_id\_map](#output\_security\_group\_id\_map) | map Security Group with ID |
| <a name="output_security_group_ids_list"></a> [security\_group\_ids\_list](#output\_security\_group\_ids\_list) | list ID for ALL Security Group |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | n/a |
<!-- END_TF_DOCS -->