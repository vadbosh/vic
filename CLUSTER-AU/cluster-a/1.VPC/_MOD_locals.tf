
locals {
  cluster_letter = {
    letter = "a"
  }
  cluster_env = {
    expected_region       = var.region
    expected_env          = "thoth-production"
    expected_main_backend = "vpc-${local.cluster_letter.letter}"
  }
}

