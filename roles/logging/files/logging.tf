resource "kubernetes_namespace" "ns_logging" {
    metadata {
      name = "logging"
    }
}

resource "helm_release" "rel_logging_operator" {
    repository = "https://kubernetes-charts.banzaicloud.com"
    name = "logging-operator"
    namespace = "logging"
    chart = "logging-operator"

    set {
        name = "createCustomResource"
        value = "false"
    }
}
