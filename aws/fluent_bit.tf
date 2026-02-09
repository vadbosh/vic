
resource "helm_release" "fluent_bit" {
  namespace  = "fluentbit"
  name       = "fluent-bit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  version    = "0.54.1"
  wait       = true
  timeout    = "600"

  depends_on = [
    module.fluent_bit_db_creds
  ]

  values = [
    file("fluent-bit-values.yaml")
  ]
}
