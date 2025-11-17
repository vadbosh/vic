
module "node_local_dns_version" {
  source             = "./modules/helm-version"
  chart_name         = "node-local-dns"
  versions_file_path = "${path.root}/helm_versions.json"
}


resource "helm_release" "node-local-dns" {
  count      = module.node_local_dns_version.version != null ? 1 : 0
  namespace  = "kube-system"
  name       = "deliveryhero"
  repository = "oci://ghcr.io/deliveryhero/helm-charts"
  chart      = "node-local-dns"
  version    = module.node_local_dns_version.version
}

