variable "region" {
  description = "The name of the AWS Region"
  type        = string
}

variable "cluster-name" {
  description = "The name of the EKS Cluster"
  type        = string
}

variable "k8s_cidr_block_associations" {
  type = string
}

variable "cidr_create" {
  type = bool
}

variable "aws_vpcs_tag_name" {
  type = string
}

variable "aws_internet_gateway_tag_name" {
  type = string
}

variable "max_nats" {
  type = string
}

variable "ssh_key_pair_name" {
  type = string
}

variable "ingress_ports" {
  description = "TCP Ingess SG default ports"
  type        = list(number)
  default     = [80, 443]
}

variable "security_group_names" {
  description = "List of names for the Security Groups to be created"
  type        = list(string)
}

