
locals {
  cluster_env = {
    expected_region       = var.region
    expected_env          = "thoth-production"
    expected_main_backend = "peering"
  }
}

