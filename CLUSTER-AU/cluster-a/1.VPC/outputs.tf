
output "region" {
  value = var.region
}

output "key_name" {
  value = aws_key_pair.ssh_key_pair.key_name
}

output "private_subnet_ids" {
  value = module.subnets.private_subnet_ids
}

output "private_subnet_cidrs" {
  value = join(",", module.subnets.private_subnet_cidrs)
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

output "cluster-name" {
  value = var.cluster-name
}

output "security_group_id_map" {
  description = "map Security Group with ID"
  value = {
    for key, sg in aws_security_group.externally_managed_rules_sg : sg.name => sg.id
  }
}

output "security_group_ids_list" {
  description = "list ID for ALL Security Group"
  value       = values(aws_security_group.externally_managed_rules_sg)[*].id
}

