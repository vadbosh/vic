resource "kubernetes_persistent_volume_claim" "demo" {
  metadata {
    namespace = "dev"
    name      = "demo-nfs"
    labels = {
      "app.kubernetes.io/instance" : "dev"
    }
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "efs-sc"
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
}

