module "flexible_rbac_with_sa" {
  source           = "./modules/rbac-generic"
  role_name_prefix = "pods4api-rbac"
  rbac_configs = [
    {
      namespace              = var.studio_cilium_policy.namespace
      service_account_name   = var.studio_cilium_policy.service_account_name
      cluster_wide           = true
      create_service_account = true
      rules = [
        {
          api_groups = ["cilium.io"]
          resources  = ["ciliumnetworkpolicies", "ciliumclusterwidenetworkpolicies"]
          verbs      = ["*"]
        }
        #{
        #  api_groups = [""] # core
        #  resources  = ["pods"]
        #  verbs      = ["get", "list", "watch"]
        #}
      ]
    },
    {
      namespace              = "thoth-production"
      service_account_name   = "default"
      cluster_wide           = false
      create_service_account = false
      rules = [
        {
          api_groups = [""] # core
          resources  = ["pods"]
          verbs      = ["get", "list", "watch"]
        }

      ]
    }
  ]
}

resource "kubernetes_secret_v1" "sa_token_secret_studio" {
  metadata {
    name      = "${var.studio_cilium_policy.service_account_name}-token"
    namespace = var.studio_cilium_policy.namespace
    annotations = {
      "kubernetes.io/service-account.name" = var.studio_cilium_policy.service_account_name
    }
  }
  type       = "kubernetes.io/service-account-token"
  depends_on = [module.flexible_rbac_with_sa]
}

output "all_roles_and_clusterroles" {
  value = module.flexible_rbac_with_sa.role_and_clusterrole_names
}

output "all_bindings_and_clusterbindings" {
  value = module.flexible_rbac_with_sa.binding_and_clusterbinding_names
}

output "created_sas" {
  value = module.flexible_rbac_with_sa.created_service_account_names
}
