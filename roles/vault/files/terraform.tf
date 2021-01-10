terraform {
  required_version = ">= 0.13"
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.9.4"
    }
  }
}

provider  "kubernetes" {}

provider "kubectl" {}

provider "helm" {}

provider "http" {}