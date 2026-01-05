
module "keda_version" {
  source             = "./modules/helm-version"
  chart_name         = "keda"
  versions_file_path = "${path.root}/helm_versions.json"
}

resource "helm_release" "keda" {
  count      = module.keda_version.version != null ? 1 : 0
  name       = "keda"
  repository = "https://kedacore.github.io/charts"
  chart      = "keda"
  namespace  = var.keda_namespace
  version    = module.keda_version.version
  values = [
    <<-EOT
serviceAccount:
  operator:
    create: true
    name: "${var.keda_service_account_name}"
    annotations:
      eks.amazonaws.com/role-arn: "${module.iam_assumable_role_keda.iam_role_arn}"
nodeSelector: { "eks-cluster/nodegroup": "${data.terraform_remote_state.eks_core.outputs.cluster-name}-metrics", }
env:
  - name: KEDA_OPERATOR_ACTIVITY_TIMEOUT
    value: "30s"
  - name: KEDA_OPERATOR_SYNC_PERIOD
    value: "15s"
  - name: KEDA_LOG_LEVEL
    value: "info"  # debug, info, warn, error
EOT
  ]
  depends_on = [
    module.iam_assumable_role_keda.iam_role_arn
  ]
}

