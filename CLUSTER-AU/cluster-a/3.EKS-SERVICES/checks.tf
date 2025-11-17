locals {
  backend_key = trimspace(regex("key\\s*=\\s*\"([^\"]+)\"", file("${path.module}/_MOD_backend-config.tfvars"))[0])
  key_parts   = split("/", local.backend_key)
}

check "validate_main_s3_key" {
  assert {
    condition = (
      length(local.key_parts) == 4 &&
      local.key_parts[0] == local.cluster_env.expected_region &&
      local.key_parts[1] == local.cluster_env.expected_env &&
      local.key_parts[2] == local.cluster_env.expected_main_backend &&
      local.key_parts[3] == "terraform.tfstate"
    )
    error_message = format(
      "The key '%s' is incorrect.\nIt must contain the region='%s', env='%s', main_backend='%s'",
      local.backend_key,
      local.cluster_env.expected_region,
      local.cluster_env.expected_env,
      local.cluster_env.expected_main_backend
    )
  }
}

check "validate_s3_key_for_eks_data" {
  assert {
    condition = (
      contains(split("/", var.s3_key_eks_data), local.cluster_env.expected_region) &&
      contains(split("/", var.s3_key_eks_data), local.cluster_env.expected_env) &&
      contains(split("/", var.s3_key_eks_data), local.cluster_env.expected_eks)
    )
    error_message = format(
      "The key '%s' is incorrect.\nIt must contain the region='%s', env='%s', eks_backend='%s'",
      var.s3_key_eks_data,
      local.cluster_env.expected_region,
      local.cluster_env.expected_env,
      local.cluster_env.expected_eks
    )
  }
}

check "validate_s3_key_for_vpc_data" {
  assert {
    condition = (
      contains(split("/", var.s3_key_vpc_data), local.cluster_env.expected_region) &&
      contains(split("/", var.s3_key_vpc_data), local.cluster_env.expected_env) &&
      contains(split("/", var.s3_key_vpc_data), local.cluster_env.expected_vpc)
    )
    error_message = format(
      "The key '%s' is incorrect.\nIt must contain the region='%s', env='%s', vpc_backend '%s'",
      var.s3_key_vpc_data,
      local.cluster_env.expected_region,
      local.cluster_env.expected_env,
      local.cluster_env.expected_vpc
    )
  }
}

