
data "aws_sns_topic" "existing_sns" {
  name = "EKSAlertTEST"
}

# IAM Policy for SNS
resource "aws_iam_policy" "sns_publish_policy" {
  name        = "victoria-metrics-sns-publish-${data.terraform_remote_state.eks_core.outputs.cluster-name}"
  description = "Allow Victoria Metrics AlertManager to publish to SNS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = data.aws_sns_topic.existing_sns.arn
      }
    ]
  })
}

# Pod Identity Association for AlertManager
resource "aws_iam_role" "alertmanager_sns_role" {
  name = "alertmanager-sns-role-${data.terraform_remote_state.eks_core.outputs.cluster-name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })
  tags = {
    Name        = "alertmanager-sns-role"
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "alertmanager_sns_policy_attach" {
  role       = aws_iam_role.alertmanager_sns_role.name
  policy_arn = aws_iam_policy.sns_publish_policy.arn
}

# EKS Pod Identity Association
resource "aws_eks_pod_identity_association" "alertmanager_sns" {
  cluster_name    = data.terraform_remote_state.eks_core.outputs.cluster-name
  namespace       = "monitoring"
  service_account = local.service_account.victoria_metrics_alert
  role_arn        = aws_iam_role.alertmanager_sns_role.arn
  depends_on = [
    kubernetes_service_account_v1.alertmanager_sa,
  ]
}

