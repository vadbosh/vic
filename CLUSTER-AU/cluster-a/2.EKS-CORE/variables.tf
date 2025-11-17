variable "aws_account_id" {
  type = string
}

variable "cluster-name" {
  description = "The name of the EKS Cluster"
  type        = string
}

variable "k8s-version" {
  description = "Kubernetes master version"
  type        = string
}

variable "compile_cidr_block_associations" {
  type = string
}

variable "s3_key_vpc_data" {
  type = string
}

variable "nodegroup_prefix" {
  type = string
}

