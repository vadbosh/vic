# main.tf in modules/ssm-k8s-secret

# Fetch parameters from AWS SSM Parameter Store
module "ssm_parameters" {
  source         = "cloudposse/ssm-parameter-store/aws"
  parameter_read = values(var.ssm_parameters)
}

# Create a Kubernetes secret with the fetched parameters
resource "kubernetes_secret_v1" "this" {
  metadata {
    name      = var.secret_name
    namespace = var.secret_namespace
  }

  data = {
    for secret_key, ssm_path in var.ssm_parameters :
    secret_key => module.ssm_parameters.values[index(module.ssm_parameters.names, ssm_path)]
  }

  type = var.secret_type
}
