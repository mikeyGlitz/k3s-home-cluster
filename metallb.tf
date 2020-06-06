resource "kubernetes_namespace" "ns_metallb" {
  metadata {
      name = "metallb-system"
  }
}

resource "helm_release" "rel_metallb" {
    repository = "https://charts.bitnami.com/bitnami"
    chart = "metallb"
    namespace = "metallb-system"
    name = "metallb"

    set {
        name = "configInline"
        value = file("./metallb.config.yaml")
    }
}

