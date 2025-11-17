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
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.0.2 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws_lb_controller_pod_identity"></a> [aws\_lb\_controller\_pod\_identity](#module\_aws\_lb\_controller\_pod\_identity) | terraform-aws-modules/eks-pod-identity/aws | n/a |
| <a name="module_aws_load_balancer_controller_version"></a> [aws\_load\_balancer\_controller\_version](#module\_aws\_load\_balancer\_controller\_version) | ./modules/helm-version | n/a |
| <a name="module_cluster_autoscaler_version"></a> [cluster\_autoscaler\_version](#module\_cluster\_autoscaler\_version) | ./modules/helm-version | n/a |
| <a name="module_eks-aws-auth"></a> [eks-aws-auth](#module\_eks-aws-auth) | terraform-aws-modules/eks/aws//modules/aws-auth | ~> 20.0 |
| <a name="module_external_ingress_nginx_shared_version"></a> [external\_ingress\_nginx\_shared\_version](#module\_external\_ingress\_nginx\_shared\_version) | ./modules/helm-version | n/a |
| <a name="module_external_ingress_nginx_version"></a> [external\_ingress\_nginx\_version](#module\_external\_ingress\_nginx\_version) | ./modules/helm-version | n/a |
| <a name="module_flexible_rbac_with_sa"></a> [flexible\_rbac\_with\_sa](#module\_flexible\_rbac\_with\_sa) | ./modules/rbac-generic | n/a |
| <a name="module_ingress_nginx_version"></a> [ingress\_nginx\_version](#module\_ingress\_nginx\_version) | ./modules/helm-version | n/a |
| <a name="module_metrics_server_version"></a> [metrics\_server\_version](#module\_metrics\_server\_version) | ./modules/helm-version | n/a |
| <a name="module_node_local_dns_version"></a> [node\_local\_dns\_version](#module\_node\_local\_dns\_version) | ./modules/helm-version | n/a |
| <a name="module_node_role_labeler"></a> [node\_role\_labeler](#module\_node\_role\_labeler) | ./modules/rbac-generic | n/a |
| <a name="module_reflector_version"></a> [reflector\_version](#module\_reflector\_version) | ./modules/helm-version | n/a |
| <a name="module_reloader_version"></a> [reloader\_version](#module\_reloader\_version) | ./modules/helm-version | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_eks_access_entry.sso_admin_role_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_entry) | resource |
| [aws_eks_access_entry.sso_user_role_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_entry) | resource |
| [aws_eks_access_policy_association.sso_admin_policy_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_policy_association) | resource |
| [aws_eks_access_policy_association.sso_user_policy_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_policy_association) | resource |
| [helm_release.as-server](https://registry.terraform.io/providers/hashicorp/helm/3.0.2/docs/resources/release) | resource |
| [helm_release.aws-load-balancer-controller](https://registry.terraform.io/providers/hashicorp/helm/3.0.2/docs/resources/release) | resource |
| [helm_release.external_ingress_nginx](https://registry.terraform.io/providers/hashicorp/helm/3.0.2/docs/resources/release) | resource |
| [helm_release.external_ingress_nginx_shared](https://registry.terraform.io/providers/hashicorp/helm/3.0.2/docs/resources/release) | resource |
| [helm_release.internal_ingress_nginx](https://registry.terraform.io/providers/hashicorp/helm/3.0.2/docs/resources/release) | resource |
| [helm_release.metrics-server](https://registry.terraform.io/providers/hashicorp/helm/3.0.2/docs/resources/release) | resource |
| [helm_release.node-local-dns](https://registry.terraform.io/providers/hashicorp/helm/3.0.2/docs/resources/release) | resource |
| [helm_release.reflector](https://registry.terraform.io/providers/hashicorp/helm/3.0.2/docs/resources/release) | resource |
| [helm_release.reloader](https://registry.terraform.io/providers/hashicorp/helm/3.0.2/docs/resources/release) | resource |
| [kubernetes_cluster_role.cluster_autoscaler_volume_role](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role) | resource |
| [kubernetes_cluster_role_binding.cluster_autoscaler_volume_binding](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_binding) | resource |
| [kubernetes_daemon_set_v1.node_role_labeler](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/daemon_set_v1) | resource |
| [kubernetes_namespace.namespaces](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret_v1.sa_token_secret_studio](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [kubernetes_service_account.alb_sa](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [kubernetes_storage_class.ebs_sc](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class) | resource |
| [null_resource.node_role_labeler_script_updater](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [kubernetes_config_map.aws_auth](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/config_map) | data source |
| [terraform_remote_state.eks_core](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |
| [terraform_remote_state.network](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_autoscaler_image_tag"></a> [cluster\_autoscaler\_image\_tag](#input\_cluster\_autoscaler\_image\_tag) | n/a | `string` | n/a | yes |
| <a name="input_ingress_external_config"></a> [ingress\_external\_config](#input\_ingress\_external\_config) | Configuration for the external monolith Nginx Ingress. Must be provided via tfvars. | <pre>object({<br/>    class_name        = string<br/>    helm_release_name = string<br/>    chart_name        = string<br/>    namespace         = string<br/>  })</pre> | n/a | yes |
| <a name="input_ingress_external_shared_config"></a> [ingress\_external\_shared\_config](#input\_ingress\_external\_shared\_config) | Configuration for the external shared Nginx Ingress. Must be provided via tfvars. | <pre>object({<br/>    class_name        = string<br/>    helm_release_name = string<br/>    chart_name        = string<br/>    namespace         = string<br/>  })</pre> | n/a | yes |
| <a name="input_ingress_internal_config"></a> [ingress\_internal\_config](#input\_ingress\_internal\_config) | Configuration for the Internal Nginx Ingress. Must be provided via tfvars. | <pre>object({<br/>    class_name        = string<br/>    helm_release_name = string<br/>    chart_name        = string<br/>    namespace         = string<br/>  })</pre> | n/a | yes |
| <a name="input_namespaces"></a> [namespaces](#input\_namespaces) | n/a | `list(string)` | n/a | yes |
| <a name="input_s3_key_eks_data"></a> [s3\_key\_eks\_data](#input\_s3\_key\_eks\_data) | n/a | `string` | n/a | yes |
| <a name="input_s3_key_vpc_data"></a> [s3\_key\_vpc\_data](#input\_s3\_key\_vpc\_data) | n/a | `string` | n/a | yes |
| <a name="input_studio_cilium_policy"></a> [studio\_cilium\_policy](#input\_studio\_cilium\_policy) | n/a | <pre>object({<br/>    service_account_name = string<br/>    namespace            = string<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_all_bindings_and_clusterbindings"></a> [all\_bindings\_and\_clusterbindings](#output\_all\_bindings\_and\_clusterbindings) | n/a |
| <a name="output_all_roles_and_clusterroles"></a> [all\_roles\_and\_clusterroles](#output\_all\_roles\_and\_clusterroles) | n/a |
| <a name="output_aws-lb-controller_service_account"></a> [aws-lb-controller\_service\_account](#output\_aws-lb-controller\_service\_account) | n/a |
| <a name="output_created_sas"></a> [created\_sas](#output\_created\_sas) | n/a |
<!-- END_TF_DOCS -->