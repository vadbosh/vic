
provider "aws" {
  #profile = var.profile
  region = data.terraform_remote_state.network.outputs.region
}

provider "external" {}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}
