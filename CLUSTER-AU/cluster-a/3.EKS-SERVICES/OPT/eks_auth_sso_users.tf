
resource "aws_eks_access_entry" "sso_admin_role_access" {
  cluster_name  = data.aws_eks_cluster.eks_cluster.name
  principal_arn = "arn:aws:iam::${var.aws_account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AWSAdministratorAccess_2f0885e508cc7257"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "sso_admin_policy_association" {
  cluster_name  = data.aws_eks_cluster.eks_cluster.name
  principal_arn = aws_eks_access_entry.sso_admin_role_access.principal_arn
  #policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope {
    type = "cluster"
  }
  depends_on = [aws_eks_access_entry.sso_admin_role_access]
}

