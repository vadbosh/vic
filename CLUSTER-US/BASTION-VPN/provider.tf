
provider "external" {}

provider "aws" {
  #profile = var.profile
  region = data.terraform_remote_state.network.outputs.region
}
