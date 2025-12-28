# variables.tf in modules/ssm-k8s-secret

variable "secret_name" {
  description = "The name of the Kubernetes secret to create."
  type        = string
}

variable "secret_namespace" {
  description = "The namespace in which to create the Kubernetes secret."
  type        = string
}

variable "ssm_parameters" {
  description = "A map where keys are the secret keys and values are the SSM parameter paths."
  type        = map(string)
}

variable "secret_type" {
  description = "The type of the Kubernetes secret."
  type        = string
  default     = "Opaque"
}
