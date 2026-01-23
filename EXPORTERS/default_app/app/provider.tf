
provider "aws" {
  #profile = var.profile
  region = var.region
}

terraform {
  required_version = ">= 0.14"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.17.0" #"~> 5.99.1"
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
      version = ">= 2.38.0" #">= 2.37.1"
    }
    acme = {
      source  = "vancluever/acme"
      version = "2.35.0" #"2.32.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.2" #"2.17.0"
    }
  }
}

provider "external" {}


provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}



provider "kubernetes" {
  config_path = "~/.kube/config"
}



