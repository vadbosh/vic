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

