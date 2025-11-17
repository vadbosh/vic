
variable "namespaces" {
  type = list(string)
}

#variable "aws_load_balancer_name_external" {
#  type        = string
#  description = "Name of aws_load_balancer_name_external"
#}

variable "s3_key_eks_data" {
  type = string
}

variable "s3_key_vpc_data" {
  type = string
}

variable "cluster_autoscaler_image_tag" {
  type        = string
  description = ""
}

variable "ingress_internal_config" {
  description = "Configuration for the Internal Nginx Ingress. Must be provided via tfvars."
  type = object({
    class_name        = string
    helm_release_name = string
    chart_name        = string
    namespace         = string
  })
}

variable "ingress_external_config" {
  description = "Configuration for the external monolith Nginx Ingress. Must be provided via tfvars."
  type = object({
    class_name        = string
    helm_release_name = string
    chart_name        = string
    namespace         = string
  })
}

variable "ingress_external_shared_config" {
  description = "Configuration for the external shared Nginx Ingress. Must be provided via tfvars."
  type = object({
    class_name        = string
    helm_release_name = string
    chart_name        = string
    namespace         = string
  })
}

variable "studio_cilium_policy" {
  type = object({
    service_account_name = string
    namespace            = string
  })
}

#variable "security_group_name_igress_external" {
#  type = string
#}

