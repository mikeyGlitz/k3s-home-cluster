terraform {
  required_version = "> v0.12"
}

provider "http" {
  
}


provider "helm" {
}

provider "kubernetes" {
  config_context_cluster   = "haus.net"
}

provider "kubectl" {
  config_context_cluster   = "haus.net"
}

