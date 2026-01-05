locals {
  cert_manager_version    = "1.19.1" # !! https://github.com/cert-manager/cert-manager/releases
  root_wellnessliving_com = "wellnessliving.com"
}

data "http" "cert_manager_crds" {
  url = "https://github.com/cert-manager/cert-manager/releases/download/v${local.cert_manager_version}/cert-manager.crds.yaml"
}

resource "kubectl_manifest" "cert_manager_crds" {
  yaml_body = data.http.cert_manager_crds.response_body
}

data "aws_route53_zone" "wellnessliving_com" {
  name = "${local.root_wellnessliving_com}."
}

module "cert_manager" {
  source                                 = "terraform-iaac/cert-manager/kubernetes"
  chart_version                          = local.cert_manager_version # https://artifacthub.io/packages/helm/cert-manager/cert-manager
  create_namespace                       = false
  cluster_issuer_email                   = "vad.v.bosh@gmail.com"
  cluster_issuer_name                    = "wellnessliving-com"
  cluster_issuer_private_key_secret_name = "wellnessliving-com"
  #cluster_issuer_server                  = "https://acme-staging-v02.api.letsencrypt.org/directory"
  cluster_issuer_server = "https://acme-v02.api.letsencrypt.org/directory"
  depends_on = [
    kubernetes_secret_v1.route53_access_key,
    kubernetes_secret_v1.route53_key_id,
    kubectl_manifest.cert_manager_crds
  ]

  additional_set = [
    {
      name  = "installCRDs"
      value = false
    },
    #{
    #  name  = "crds.enabled"
    #  value = true
    #},
    {
      name  = "prometheus.enabled"
      value = false
    },
    {
      name  = "nodeSelector.eks-cluster/nodegroup"
      value = "${data.terraform_remote_state.eks_core.outputs.cluster-name}-metrics"
    },
    {
      name  = "cainjector.nodeSelector.eks-cluster/nodegroup"
      value = "${data.terraform_remote_state.eks_core.outputs.cluster-name}-metrics"
    },
    {
      name  = "webhook.nodeSelector.eks-cluster/nodegroup"
      value = "${data.terraform_remote_state.eks_core.outputs.cluster-name}-metrics"
    }
  ]

  solvers = [
    {
      dns01 = {
        route53 = {
          ambient      = "true"
          region       = data.terraform_remote_state.network.outputs.region
          accessKeyID  = values(kubernetes_secret_v1.route53_key_id.data).0
          hostedZoneID = data.aws_route53_zone.wellnessliving_com.zone_id
          secretAccessKeySecretRef = {
            name = kubernetes_secret_v1.route53_access_key.metadata[0].name
            key  = keys(kubernetes_secret_v1.route53_access_key.data).0
          }
        },
      },
      selector = {
        dnsZones = ["${local.root_wellnessliving_com}"]
      }
    }
  ]

  certificates = {
    "wellnessliving-com" = {
      secret_annotations = {
        "reflector.v1.k8s.emberstack.com/reflection-auto-enabled"       = "true"
        "reflector.v1.k8s.emberstack.com/reflection-allowed"            = "true"
        "reflector.v1.k8s.emberstack.com/reflection-allowed-namespaces" = "default,monolith-stable,monolith-trunk,monitoring"
      }
      dns_names   = ["*.wellnessliving.com", "wellnessliving.com", "*.ms.thoth.wellnessliving.com", "*.staging.wellnessliving.com", "*.demo.wellnessliving.com"]
      namespace   = "default"
      issuer_kind = "ClusterIssuer"
      issuer_name = "wellnessliving-com"
      secret_name = "wellnessliving-com"
    }
  }
}

