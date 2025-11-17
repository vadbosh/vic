<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_acme"></a> [acme](#requirement\_acme) | 2.35.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.99.1 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | 3.0.2 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.38.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.5.3 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.7.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.99.1 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.0.2 |
| <a name="provider_http"></a> [http](#provider\_http) | 3.5.0 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 1.19.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.2 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_acme_parameter_store"></a> [acme\_parameter\_store](#module\_acme\_parameter\_store) | cloudposse/ssm-parameter-store/aws | n/a |
| <a name="module_cert_manager"></a> [cert\_manager](#module\_cert\_manager) | terraform-iaac/cert-manager/kubernetes | n/a |
| <a name="module_cilium_version"></a> [cilium\_version](#module\_cilium\_version) | ./modules/helm-version | n/a |
| <a name="module_iam_assumable_role_keda"></a> [iam\_assumable\_role\_keda](#module\_iam\_assumable\_role\_keda) | github.com/terraform-aws-modules/terraform-aws-iam//modules/iam-role-for-service-accounts-eks | v5.60.0 |
| <a name="module_keda_version"></a> [keda\_version](#module\_keda\_version) | ./modules/helm-version | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.keda_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role_policy_attachment.keda_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [helm_release.cilium](https://registry.terraform.io/providers/hashicorp/helm/3.0.2/docs/resources/release) | resource |
| [helm_release.keda](https://registry.terraform.io/providers/hashicorp/helm/3.0.2/docs/resources/release) | resource |
| [kubectl_manifest.cert_manager_crds](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_secret_v1.route53_access_key](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [kubernetes_secret_v1.route53_key_id](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_route53_zone.wellnessliving_com](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [http_http.cert_manager_crds](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [terraform_remote_state.eks_core](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |
| [terraform_remote_state.network](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_keda_namespace"></a> [keda\_namespace](#input\_keda\_namespace) | Namespace to deploy KEDA into | `string` | n/a | yes |
| <a name="input_keda_service_account_name"></a> [keda\_service\_account\_name](#input\_keda\_service\_account\_name) | Keda service account name | `string` | n/a | yes |
| <a name="input_s3_key_eks_data"></a> [s3\_key\_eks\_data](#input\_s3\_key\_eks\_data) | n/a | `string` | n/a | yes |
| <a name="input_s3_key_vpc_data"></a> [s3\_key\_vpc\_data](#input\_s3\_key\_vpc\_data) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_keda_iam_role_arn"></a> [keda\_iam\_role\_arn](#output\_keda\_iam\_role\_arn) | --- Output the role ARN --- |
<!-- END_TF_DOCS -->