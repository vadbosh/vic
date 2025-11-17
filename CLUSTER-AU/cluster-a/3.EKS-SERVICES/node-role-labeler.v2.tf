# ==============================================================================
# Kubernetes Node Role Labeler
#
# This file defines all resources needed to automatically apply a Kubernetes "Role"
# label to EKS nodes based on a "signal" label.
# ==============================================================================

# ------------------------------------------------------------------------------
# Reminder: Provider Configuration
# ------------------------------------------------------------------------------
# Make sure you have a Kubernetes provider configured with an alias in your project,
# as the resources below depend on it. Example:
#
# provider "kubernetes" {
#   alias                  = "eks_cluster"
#   host                   = module.eks.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
#   token                  = data.aws_eks_cluster_auth.this.token
# }
# ------------------------------------------------------------------------------

# --- 1: (DRY - Don't Repeat Yourself) ---
locals {
  node_labeler_script = <<-EOT
    echo "20251106Z1947"
    while true; do
      set -e
      # !!! if ! command -v jq &>/dev/null; then yum install -y jq >/dev/null 2>&1; fi
      NODE_NAME=$(NODE_NAME_ENV)
      # ------------------------------------------------------------------------------------
      LABELS_DATA=$(kubectl get node $${NODE_NAME} --output=jsonpath='{.metadata.labels.k8s/node-role},{.metadata.labels.topology\.kubernetes\.io/zone}')
      IFS=',' read -r ROLE_PART ZONE_PART <<< "$${LABELS_DATA}"
      if [ -n "$${ROLE_PART}" ]; then
        COMBINED_ROLE="$${ROLE_PART}"
        if [ -n "$${ZONE_PART}" ]; then
          COMBINED_ROLE="$${COMBINED_ROLE}_$${ZONE_PART}"
        fi
        DESIRED_ROLE_LABEL="node-role.kubernetes.io/$${COMBINED_ROLE}"
        ALL_LABELS_JSON=$(kubectl get node $${NODE_NAME} -o jsonpath='{.metadata.labels}')
        if ! echo "$${ALL_LABELS_JSON}" | grep -q "\"$${DESIRED_ROLE_LABEL}\":"; then
            echo "Applying desired role label: $${DESIRED_ROLE_LABEL}="
            kubectl label node $${NODE_NAME} "$${DESIRED_ROLE_LABEL}=" --overwrite
        fi
        for existing_label in $(echo "$${ALL_LABELS_JSON}" | jq -r 'keys[] | select(. | startswith("node-role.kubernetes.io/"))'); do
          if [ "$${existing_label}" != "$${DESIRED_ROLE_LABEL}" ]; then
            echo "Removing stale role label: $${existing_label}"
            kubectl label node $${NODE_NAME} "$${existing_label}-" --overwrite
          fi
        done
      fi
      # ------------------------------------------------------------------------------------
      PROVIDER_ID=$(kubectl get node $${NODE_NAME} --output=jsonpath='{.spec.providerID}')
      HOSTNAME=$(kubectl get node $${NODE_NAME} --output=jsonpath='{.metadata.labels.kubernetes\.io/hostname}')
      if [ -n "$${PROVIDER_ID}" ] && [ -n "$${HOSTNAME}" ]; then
        INSTANCE_ID=$(echo "$${PROVIDER_ID}" | sed 's#.*/##')
        if [ -n "$${INSTANCE_ID}" ]; then
          NEW_HOSTNAME=$(echo "$${HOSTNAME}" | sed -E "s#(\.ec2\.internal|\.compute\.internal)#.$${INSTANCE_ID}#")
          CURRENT_CUSTOM_HOSTNAME=$(kubectl get node $${NODE_NAME} --output=jsonpath='{.metadata.labels.custom/hostname-id}')
          if [ "$${CURRENT_CUSTOM_HOSTNAME}" != "$${NEW_HOSTNAME}" ]; then
            kubectl label node $${NODE_NAME} "custom/hostname-id=$${NEW_HOSTNAME}" --overwrite >/dev/null 2>&1
          fi
        fi
      fi
      # ------------------------------------------------------------------------------------
      sleep 300
    done
  EOT
}


# ---  2: ---
# This resource doesn't create anything, but it has an 'id' that changes
# whenever its 'triggers' change. We use this to automatically trigger a rollout.
resource "null_resource" "node_role_labeler_script_updater" {
  triggers = {
    # Calculate the SHA256 hash of our script. If the script text changes,
    # this hash will change, which will cause this resource to be "re-created".
    script_sha256 = sha256(local.node_labeler_script)
  }
}

# --- 3:  RBAC (ServiceAccount, Role, Binding) ---
module "node_role_labeler" {
  source = "./modules/rbac-generic"
  #providers = {
  #  kubernetes = kubernetes.eks_cluster
  #}
  role_name_prefix = "node-role-labeler"
  rbac_configs = [
    {
      namespace              = "kube-system"
      service_account_name   = "node-role-labeler"
      cluster_wide           = true
      create_service_account = true
      rules = [
        {
          api_groups = [""]
          resources  = ["nodes"]
          verbs      = ["get", "patch"]
        }
      ]
    }
  ]
}

# --- 4: DaemonSet ---
resource "kubernetes_daemon_set_v1" "node_role_labeler" {
  #provider = kubernetes.eks_cluster 

  depends_on = [module.node_role_labeler]

  metadata {
    name      = "node-role-labeler"
    namespace = "kube-system"
    labels = {
      app = "node-role-labeler"
    }
  }

  spec {
    selector {
      match_labels = {
        app = "node-role-labeler"
      }
    }

    template {
      metadata {
        labels = {
          app = "node-role-labeler"
        }
        annotations = {
          # The rollout trigger is now linked to the ID of our null_resource.
          # This ID changes only when the script's hash changes, triggering an update.
          "rollout-trigger" = null_resource.node_role_labeler_script_updater.id
        }
      }

      spec {
        service_account_name = join("", module.node_role_labeler.created_service_account_names)
        host_network         = true
        priority_class_name  = "system-cluster-critical"

        toleration {
          operator = "Exists"
        }

        container {
          name  = "kubectl"
          image = "alpine/k8s:1.33.5"
          #image             = "bitnami/kubectl:latest"
          image_pull_policy = "IfNotPresent"
          command           = ["/bin/bash", "-c"]

          # We now reference the script from the 'locals' block.
          args = [local.node_labeler_script]

          env {
            name = "NODE_NAME_ENV"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }
        }
      }
    }
  }
}
