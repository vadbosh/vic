variable "region" {
  description = "The name of the AWS Region"
  type        = string
}

variable "profile" {
  description = "The name of the AWS profile in the credentials file"
  type        = string
  default     = "terraform_deploy"
}

variable "deploy_env" {
  description = "Namespace k8s in which the application will be deployed"
  type        = string
}

variable "app_name" {
  description = "Name of application to deploy"
  type        = string
}

variable "repository_name" {
  description = "Repository name of application Docker image to deploy"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag of the application being deployed"
  type        = string
}

variable "replicas" {
  description = "Number of pods of application being deployed"
  default     = "1"
  type        = string
}

variable "chart_version" {
  description = "Helm chart version"
  type        = string
}

variable "ecr" {
  description = "AWS Elastic Container Registry URL"
  type        = string
}

variable "nodepool" {
  description = "nodeSelector to select nodes for application deployment"
  type        = string
}

variable "PDB_minAvailable" {
  type    = string
  default = "75%"
}

variable "rollingUpdate_maxSurge" {
  type = string
}

variable "rollingUpdate_maxUnavailable" {
  type = string
}

variable "health_check" {
  type = string
}

variable "app_port" {
  type = string
}

variable "app_domain" {
  type = string
}

variable "resource_limit_cpu" {
  type = string
}

variable "resource_limit_memory" {
  type = string
}

variable "resource_request_cpu" {
  type = string
}

variable "resource_request_memory" {
  type = string
}

variable "minReplicas" {
  type = string
}

variable "maxReplicas" {
  type = string
}

variable "entrypoint" {
  default = "default"
  type    = string
}

variable "container_init_delay" {
  type = string
}

variable "ingress_class_name" {
  type = string
}

variable "helm_run_timeout" {
  type = string
}

variable "tls_secret_name" {
  type = string
}

# metrics part

variable "php_fpm_max_proc" {
  type = string
}

variable "fpm_metrics_port" {
  type = string
}

variable "apache_metrics_port" {
  type = string
}

variable "cpu_threshold" {
  type = string
}

variable "prometheus_threshold" {
  type = string
}


