
output "region" {
  value = var.region
}

output "key_name" {
  value = aws_key_pair.ssh_key_pair.key_name
}

output "private_subnet_ids" {
  value = module.subnets.private_subnet_ids
}

output "public_subnet_ids" {
  value = module.subnets.public_subnet_ids
}

output "cluster_top_cidr" {
  value = var.k8s_cidr_block_associations
}

output "vpc_id" {
  value = join("", data.aws_vpcs.net_workspace.ids)
}

output "nat_id" {
  value = data.aws_nat_gateways.ngws.ids
}

output "igt_id" {
  value = data.aws_internet_gateway.igtws.id
}

