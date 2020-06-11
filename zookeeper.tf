resource "helm_release" "rel_zookeeper" {
    repository = "https://kubernetes-charts.banzaicloud.com"
    chart = "zookeeper-operator"
    name = "zookeeper-operator"
    namespace = "zookeeper"
    create_namespace = true
}