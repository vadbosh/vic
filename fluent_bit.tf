
resource "helm_release" "fluent_bit" {
  namespace  = "fluentbit"
  name       = "fluent-bit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  version    = "0.54.0"
  wait       = true
  timeout    = "240"

  depends_on = [
    module.fluent_bit_parameters,
    kubernetes_secret_v1.fluent_bit_db_creds,
    kubernetes_config_map_v1.fluent_bit_lua_script
  ]

  values = [
    file("fluent-bit-values.yaml")
  ]
}
