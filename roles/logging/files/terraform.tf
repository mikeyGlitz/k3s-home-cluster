terraform {
  required_version = ">= 0.13"
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

provider  "kubernetes" {}

provider "kubectl" {}

provider "helm" {}

provider "http" {}