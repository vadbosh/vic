/*
output "network" {
  value = data.terraform_remote_state.network
}

output "eks_core" {
  value = data.terraform_remote_state.eks_core
}
*/

output "ssh_nlb_arn" {
  description = "ARN of the created SSH Network Load Balancer."
  value       = aws_lb.ssh_nlb.arn
}

output "ssh_nlb_dns_name" {
  description = "DNS name of the created SSH Network Load Balancer."
  value       = aws_lb.ssh_nlb.dns_name
}

output "ssh_nlb_name" {
  description = "name of the created SSH Network Load Balancer."
  value       = aws_lb.ssh_nlb.name
}

