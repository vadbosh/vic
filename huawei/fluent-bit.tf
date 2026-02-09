
resource "helm_release" "fluent_bit" {
  namespace  = "graylog"
  name       = "fluent-bit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  version    = "0.48.3"
  wait       = true
  timeout    = "600"
  depends_on = [helm_release.graylog]
  values = [
    "${file("fluent-bit-values.yaml")}"
  ]
}
