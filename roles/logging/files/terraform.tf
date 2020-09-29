terraform {
  required_version = ">= 0.13"
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.6.2"
    }
  }
}

provider  "kubernetes" {}

provider "kubectl" {}

provider "helm" {}

provider "http" {}