
resource "aws_eks_access_entry" "sso_admin_role_access" {
  cluster_name  = data.aws_eks_cluster.eks_cluster.name
  principal_arn = "arn:aws:iam::${data.terraform_remote_state.eks_core.outputs.aws_account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_EKS-Admin_279d69da1bb5bcff"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "sso_admin_policy_association" {
  cluster_name  = data.aws_eks_cluster.eks_cluster.name
  principal_arn = aws_eks_access_entry.sso_admin_role_access.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope {
    type = "cluster"
  }
  depends_on = [aws_eks_access_entry.sso_admin_role_access]
}

resource "aws_eks_access_entry" "sso_user_role_access" {
  cluster_name  = data.aws_eks_cluster.eks_cluster.name
  principal_arn = "arn:aws:iam::${data.terraform_remote_state.eks_core.outputs.aws_account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_EKS-Users_9d1bc522e2e6f658"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "sso_user_policy_association" {
  cluster_name  = data.aws_eks_cluster.eks_cluster.name
  principal_arn = aws_eks_access_entry.sso_user_role_access.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
  access_scope {
    type       = "namespace"
    namespaces = ["thoth-production"]
  }
  depends_on = [aws_eks_access_entry.sso_user_role_access]
}

