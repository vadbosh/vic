
terraform {
  required_version = ">= 0.14"
  backend "s3" {
    # !!! MUST RUN INIT #
    # key -> terraform init -backend-config="backend-config.tfvars"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.25.0" #"~> 5.99.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.3"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 3.0.0" #">= 2.38.0" #">= 2.37.1"
    }
    acme = {
      source  = "vancluever/acme"
      version = "2.39.0" #"2.32.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.1.1" #"2.17.0"
    }
  }
}

