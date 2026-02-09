
module "fluent_bit_db_creds" {
  source = "./modules/ssm-k8s-secret"

  secret_name      = "fluent-bit-db-creds"
  secret_namespace = "fluentbit"

  ssm_parameters = {
    PG_USER     = "/k8s/RDS/prod_fluentbit/db_user"
    PG_PASSWORD = "/k8s/RDS/prod_fluentbit/db_password"
  }
}

