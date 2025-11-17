<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_acme"></a> [acme](#requirement\_acme) | 2.35.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 6.16.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | 3.0.2 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.38.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.5.3 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.7.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.16.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.2 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws_ebs_csi_pod_identity"></a> [aws\_ebs\_csi\_pod\_identity](#module\_aws\_ebs\_csi\_pod\_identity) | terraform-aws-modules/eks-pod-identity/aws | n/a |
| <a name="module_aws_efs_csi_pod_identity"></a> [aws\_efs\_csi\_pod\_identity](#module\_aws\_efs\_csi\_pod\_identity) | terraform-aws-modules/eks-pod-identity/aws | n/a |
| <a name="module_cluster_autoscaler_pod_identity"></a> [cluster\_autoscaler\_pod\_identity](#module\_cluster\_autoscaler\_pod\_identity) | terraform-aws-modules/eks-pod-identity/aws | n/a |
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | 21.3.2 |
| <a name="module_sg_main_efs"></a> [sg\_main\_efs](#module\_sg\_main\_efs) | terraform-aws-modules/security-group/aws | n/a |
| <a name="module_sg_main_internal"></a> [sg\_main\_internal](#module\_sg\_main\_internal) | terraform-aws-modules/security-group/aws | n/a |

## Resources

| Name | Type |
|------|------|
| [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/6.16.0/docs/data-sources/caller_identity) | data source |
| [terraform_remote_state.network](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | n/a | `string` | n/a | yes |
| <a name="input_cluster-name"></a> [cluster-name](#input\_cluster-name) | The name of the EKS Cluster | `string` | n/a | yes |
| <a name="input_compile_cidr_block_associations"></a> [compile\_cidr\_block\_associations](#input\_compile\_cidr\_block\_associations) | n/a | `string` | n/a | yes |
| <a name="input_k8s-version"></a> [k8s-version](#input\_k8s-version) | Kubernetes master version | `string` | n/a | yes |
| <a name="input_nodegroup_prefix"></a> [nodegroup\_prefix](#input\_nodegroup\_prefix) | n/a | `string` | n/a | yes |
| <a name="input_s3_key_vpc_data"></a> [s3\_key\_vpc\_data](#input\_s3\_key\_vpc\_data) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_account_id"></a> [aws\_account\_id](#output\_aws\_account\_id) | n/a |
| <a name="output_cluster-name"></a> [cluster-name](#output\_cluster-name) | n/a |
| <a name="output_nodegroup_prefix"></a> [nodegroup\_prefix](#output\_nodegroup\_prefix) | n/a |
<!-- END_TF_DOCS -->