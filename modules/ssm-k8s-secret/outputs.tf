# outputs.tf in modules/ssm-k8s-secret

output "kubernetes_secret" {
  description = "The created Kubernetes secret."
  value       = kubernetes_secret_v1.this
}
