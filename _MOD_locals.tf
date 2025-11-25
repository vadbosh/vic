
locals {
  service_account = {
    victoria_metrics_alert = "vmalertmanager-sa-custom"
  }
  basic_auth_secret = {
    name = "vmagent-basic-auth"
  }
  bearer_token_secret = {
    name = "vm-bearer-token-secret"
  }
}

