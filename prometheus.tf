resource "helm_release" "rel_prometheus" {
    repository = "https://kubernetes-charts.storage.googleapis.com"
    chart = "prometheus-operator"
    name = "prometheus-operator"
    namespace = "prometheus"
    create_namespace = true
}