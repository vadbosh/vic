resource "aws_efs_file_system" "victoria_fs" {
  creation_token   = "${data.terraform_remote_state.eks_core.outputs.cluster-name}-efs"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  tags = {
    "Name" = "${data.terraform_remote_state.eks_core.outputs.cluster-name}-victoria"
    "Type" = "File System Service"
  }
}

resource "aws_efs_mount_target" "victoria" {
  count           = length(data.terraform_remote_state.network.outputs.private_subnet_ids)
  file_system_id  = aws_efs_file_system.victoria_fs.id
  subnet_id       = element(data.terraform_remote_state.network.outputs.private_subnet_ids, count.index)
  security_groups = [data.terraform_remote_state.eks_core.outputs.efs_sec_group_id]
}

resource "aws_efs_backup_policy" "victoria" {
  file_system_id = aws_efs_file_system.victoria_fs.id
  backup_policy {
    status = "DISABLED"
  }
}

resource "kubernetes_storage_class" "efs-sc" {
  metadata {
    name = "efs-sc"
  }
  reclaim_policy      = "Retain"
  storage_provisioner = "efs.csi.aws.com"
  parameters = {
    provisioningMode = "efs-ap"
    fileSystemId     = aws_efs_file_system.victoria_fs.id
    directoryPerms   = 700
    gidRangeStart    = 1000
    gidRangeEnd      = 2000
    basePath         = "/dynamic_provisioning"
  }
  depends_on = [
    aws_efs_file_system.victoria_fs,
    aws_efs_mount_target.victoria,
  ]
}

