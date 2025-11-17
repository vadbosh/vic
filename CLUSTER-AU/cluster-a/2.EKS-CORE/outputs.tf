
output "aws_account_id" {
  value = var.aws_account_id
}

output "cluster-name" {
  value = var.cluster-name
}

output "nodegroup_prefix" {
  value = var.nodegroup_prefix
}

output "efs_sec_group_id" {
  value = module.sg_main_efs.security_group_id
}

