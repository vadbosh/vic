<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_acme"></a> [acme](#requirement\_acme) | 2.31.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.94.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.36.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.5.2 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.6.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.94.1 |
| <a name="provider_aws.sydney"></a> [aws.sydney](#provider\_aws.sydney) | 5.94.1 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.6.3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc_peering"></a> [vpc\_peering](#module\_vpc\_peering) | cloudposse/vpc-peering/aws | n/a |
| <a name="module_vpc_peering_eks_2_eks"></a> [vpc\_peering\_eks\_2\_eks](#module\_vpc\_peering\_eks\_2\_eks) | cloudposse/vpc-peering-multi-account/aws | n/a |
| <a name="module_vpc_peering_prod_2_eks"></a> [vpc\_peering\_prod\_2\_eks](#module\_vpc\_peering\_prod\_2\_eks) | cloudposse/vpc-peering-multi-account/aws | n/a |
| <a name="module_vpc_peering_us-eks_2_au-prod"></a> [vpc\_peering\_us-eks\_2\_au-prod](#module\_vpc\_peering\_us-eks\_2\_au-prod) | cloudposse/vpc-peering-multi-account/aws | n/a |

## Resources

| Name | Type |
|------|------|
| [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_vpcs.net_workspace_acceptor_eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpcs) | data source |
| [aws_vpcs.net_workspace_acceptor_eks_region](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpcs) | data source |
| [aws_vpcs.net_workspace_requestor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpcs) | data source |
| [aws_vpcs.net_workspace_requestor_region](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpcs) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_vpc_acceptor"></a> [aws\_vpc\_acceptor](#input\_aws\_vpc\_acceptor) | n/a | `string` | n/a | yes |
| <a name="input_aws_vpc_acceptor_region"></a> [aws\_vpc\_acceptor\_region](#input\_aws\_vpc\_acceptor\_region) | n/a | `string` | n/a | yes |
| <a name="input_aws_vpc_requestor"></a> [aws\_vpc\_requestor](#input\_aws\_vpc\_requestor) | n/a | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The name of the AWS Region | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->