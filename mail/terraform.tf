provider "random" {}

provider "kubectl" {
    config_context_cluster = "haus.net"
}
provider "kubernetes" {
    config_context_cluster = "haus.net"
}

provider "helm" {}