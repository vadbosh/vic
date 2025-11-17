resource "kubernetes_cluster_role" "cluster_autoscaler_volume_role" {
  metadata {
    name = "cluster-autoscaler-volume-attachments"
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["volumeattachments"]
    verbs      = ["get", "list", "watch"]
  }
  depends_on = [helm_release.as-server]
}

resource "kubernetes_cluster_role_binding" "cluster_autoscaler_volume_binding" {
  metadata {
    name = "cluster-autoscaler-volume-attachments"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.cluster_autoscaler_volume_role.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = "cluster-autoscaler"
    namespace = "kube-system"
  }
  depends_on = [helm_release.as-server, kubernetes_cluster_role.cluster_autoscaler_volume_role]
}
