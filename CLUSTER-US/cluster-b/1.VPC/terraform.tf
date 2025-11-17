
terraform {
  required_version = ">= 0.14"
  backend "s3" {
    # !!! MUST RUN INIT #
    # key -> terraform init -backend-config="_MOD_backend-config.tfvars"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.94.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.3"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.2"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.36.0"
    }
    acme = {
      source  = "vancluever/acme"
      version = "2.31.0"
    }
    helm = {
      source = "hashicorp/helm"
    }
  }
}

