provider "template" {}
provider "http" {}
provider "kubernetes" {
    config_context_cluster = "haus.net"
}

provider "kubectl" {
    config_context_cluster = "haus.net"
}

provider "helm" {}