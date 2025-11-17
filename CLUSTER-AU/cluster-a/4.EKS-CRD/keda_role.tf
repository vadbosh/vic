locals {
  oidc_provider = replace(data.aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer, "https://", "")
}
# --- IAM Policy for KEDA ---
resource "aws_iam_policy" "keda_policy" {
  name        = format("%s-%s", "keda-policy", data.terraform_remote_state.eks_core.outputs.cluster-name)
  description = "IAM policy for KEDA"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ],
        "Resource" : "*"
      }
    ]
  })
}
# --- IAM Role for KEDA ---
module "iam_assumable_role_keda" {
  source = "github.com/terraform-aws-modules/terraform-aws-iam//modules/iam-role-for-service-accounts-eks?ref=v5.60.0"
  #source      = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name   = format("%s-%s", "keda-iam-role", data.terraform_remote_state.eks_core.outputs.cluster-name)
  create_role = true
  oidc_providers = {
    main = {
      provider_arn               = "arn:aws:iam::${data.terraform_remote_state.eks_core.outputs.aws_account_id}:oidc-provider/${local.oidc_provider}"
      namespace_service_accounts = ["${var.keda_namespace}:${var.keda_service_account_name}"]
    }
  }
  tags = {
    Name = format("%s-%s", "keda-iam-role", data.terraform_remote_state.eks_core.outputs.cluster-name)
  }
}
# --- Attach policy to role ---
resource "aws_iam_role_policy_attachment" "keda_attach" {
  role       = module.iam_assumable_role_keda.iam_role_name
  policy_arn = aws_iam_policy.keda_policy.arn
}
# --- Output the role ARN ---
output "keda_iam_role_arn" {
  value = module.iam_assumable_role_keda.iam_role_arn
}
