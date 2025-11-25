data "aws_ssm_parameter" "username_vic" {
  name            = "/k8s/victoria-user-sendbox"
  with_decryption = true
}

data "aws_ssm_parameter" "password_vic" {
  name            = "/k8s/victoria-pass-sendbox"
  with_decryption = true
}

resource "kubernetes_secret_v1" "vm_basic_auth_vic" {
  metadata {
    name      = "vm-basic-auth-secret"
    namespace = "monitoring"
  }
  data = {
    username = "${data.aws_ssm_parameter.username_vic.value}"
    password = "${data.aws_ssm_parameter.password_vic.value}"
  }
  type = "Opaque"
}
# ------------------------------------------------------------------
data "aws_ssm_parameter" "vmagent_ingress_auth_ssm" {
  name            = "/k8s/vmagent-ingress-auth-sandbox"
  with_decryption = true
}

resource "kubernetes_secret_v1" "vmagent_basic_auth_secret" {
  metadata {
    name      = local.basic_auth_secret.name
    namespace = "monitoring"
  }
  data = {
    "auth" = data.aws_ssm_parameter.vmagent_ingress_auth_ssm.value
  }
  type = "Opaque"
}
# ------------------------------------------------------------------
data "aws_ssm_parameter" "vmagent_bearer_token" {
  name            = "/k8s/victoria-bearer-token-sandbox"
  with_decryption = true
}

resource "kubernetes_secret_v1" "vm_bearer_token_secret" {
  metadata {
    name      = local.bearer_token_secret.name
    namespace = "monitoring"
  }
  data = {
    token = data.aws_ssm_parameter.vmagent_bearer_token.value
  }
  type = "Opaque"
}
