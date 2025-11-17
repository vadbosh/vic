/*
resource "helm_release" "aws-ebs-csi-driver" {
  namespace  = "kube-system"
  name       = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver/"
  chart      = "aws-ebs-csi-driver"
  version    = "2.36.0"
}
*/

resource "kubernetes_storage_class" "ebs_sc" {
  metadata {
    name = "ebs-sc"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  reclaim_policy      = "Delete"
  storage_provisioner = "ebs.csi.aws.com"
  volume_binding_mode = "WaitForFirstConsumer"
  # parameters = {
  # type = "gp3"
  #  encrypted = "true"
  #}
  allow_volume_expansion = true
}



