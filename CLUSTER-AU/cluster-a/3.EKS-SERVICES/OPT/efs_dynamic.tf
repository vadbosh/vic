resource "aws_efs_file_system" "app_fs" {
  creation_token   = "${var.cluster-name}-efs"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  /*
  encrypted        = true
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }
*/
  tags = {
    "Name" = "${var.cluster-name}-app"
    "Type" = "File System Service"
  }
}

resource "aws_efs_mount_target" "app" {
  count           = length(data.aws_subnets.private.ids)
  file_system_id  = aws_efs_file_system.app_fs.id
  subnet_id       = element(data.aws_subnets.private.ids, count.index)
  security_groups = [module.sg_main_efs.security_group_id]
}

resource "aws_efs_backup_policy" "app" {
  file_system_id = aws_efs_file_system.app_fs.id
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
    fileSystemId     = aws_efs_file_system.app_fs.id
    directoryPerms   = 700
    gidRangeStart    = 1000
    gidRangeEnd      = 2000
    basePath         = "/dynamic_provisioning"
  }
  depends_on = [
    aws_efs_file_system.app_fs,
    aws_efs_mount_target.app,
  ]
}

