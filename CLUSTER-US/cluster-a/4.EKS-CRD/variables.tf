
variable "keda_service_account_name" {
  type        = string
  description = "Keda service account name"
}

variable "keda_namespace" {
  type        = string
  description = "Namespace to deploy KEDA into"
}

variable "s3_key_eks_data" {
  type = string
}

variable "s3_key_vpc_data" {
  type = string
}
