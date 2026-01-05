module "acme_parameter_store" {
  source = "cloudposse/ssm-parameter-store/aws"
  parameter_read = [
    "/k8s/acme/AWS_ACCESS_KEY_ID",
    "/k8s/acme/AWS_SECRET_ACCESS_KEY",
    "/k8s/KEDA/RDS"
  ]
}

data "aws_ssm_parameter" "keda_db_connection_string" {
  name            = "/k8s/KEDA/RDS"
  with_decryption = true
}

resource "kubernetes_secret_v1" "route53_access_key" {
  metadata {
    name      = "route53-access-key"
    namespace = "cert-manager"
  }
  data = {
    route53-access-key = module.acme_parameter_store.values[index(module.acme_parameter_store.names, "/k8s/acme/AWS_SECRET_ACCESS_KEY")]
  }
}

resource "kubernetes_secret_v1" "route53_key_id" {
  metadata {
    name      = "route53-key-id"
    namespace = "cert-manager"
  }
  data = {
    route53-key-id = module.acme_parameter_store.values[index(module.acme_parameter_store.names, "/k8s/acme/AWS_ACCESS_KEY_ID")]
  }
}

