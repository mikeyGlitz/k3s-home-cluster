resource "kubernetes_namespace" "ns_kong" {
    metadata {
        name = "kong"
    }
}

resource "helm_release" "rel_kong_ing" {
    repository = "https://charts.konghq.com"
    name = "kong"
    chart = "kong"
    namespace = "kong"

    set {
        name = "ingressController.installCRDs"
        value = "false"
    }
}
