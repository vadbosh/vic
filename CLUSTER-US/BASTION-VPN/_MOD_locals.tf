
locals {
  cluster_letter = {
    letter = "a"
  }
  cluster_env = {
    expected_region       = data.terraform_remote_state.network.outputs.region
    expected_env          = "thoth-production"
    expected_main_backend = "bastion-vpc"
    expected_vpc          = "vpc-${local.cluster_letter.letter}"
  }
}

