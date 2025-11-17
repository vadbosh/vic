s3_key_eks_data = "ap-southeast-2/thoth-production/eks-core-a/terraform.tfstate"
s3_key_vpc_data = "ap-southeast-2/thoth-production/vpc-a/terraform.tfstate"

namespaces = [
  "thoth-production",
  "backup",
  "cert-manager",
  "keda"
]

ingress_internal_config = {
  class_name        = "internal-ingress"
  helm_release_name = "internal-nginx"
  namespace         = "internal-nginx"
  chart_name        = "ingress-nginx"
}

ingress_external_config = {
  class_name        = "nginx"
  helm_release_name = "ingress-nginx"
  namespace         = "ingress-nginx"
  chart_name        = "ingress-nginx"
}

ingress_external_shared_config = {
  class_name        = "shared-nginx"
  helm_release_name = "ingress-nginx-shared"
  namespace         = "ingress-nginx"
  chart_name        = "ingress-nginx"
}

studio_cilium_policy = {
  service_account_name = "studio-au-prod-ciliumnetworkpolicies"
  namespace            = "default"
}

cluster_autoscaler_image_tag = "v1.33.1"
