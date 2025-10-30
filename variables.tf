
variable "s3_key_eks_data" {
  type = string
}

variable "s3_key_vpc_data" {
  type = string
}

variable "ingress_namespaces" {
  type = list(string)
  default = [
    "ingress-nginx",
    "internal-nginx"
  ]
}

