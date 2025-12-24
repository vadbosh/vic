module "fluent_bit_parameters" {
  source = "cloudposse/ssm-parameter-store/aws"
  parameter_read = [
    "/k8s/RDS/staging_fluentbit/db_user",
    "/k8s/RDS/staging_fluentbit/db_password",
  ]
}


resource "kubernetes_secret_v1" "fluent_bit_db_creds" {
  metadata {
    name      = "fluent-bit-db-creds"
    namespace = "fluentbit"
  }
  data = {
    PG_USER     = module.fluent_bit_parameters.values[index(module.fluent_bit_parameters.names, "/k8s/RDS/staging_fluentbit/db_user")]
    PG_PASSWORD = module.fluent_bit_parameters.values[index(module.fluent_bit_parameters.names, "/k8s/RDS/staging_fluentbit/db_password")]
  }
  type = "Opaque"
}

