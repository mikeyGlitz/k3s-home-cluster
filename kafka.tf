resource "kubernetes_namespace" "ns_kafka" {
    metadata {
        name = "kafka"
    }
}

resource "helm_release" "rel_kafka_operator" {
    repository = "https://kubernetes-charts.banzaicloud.com"
    chart = "kafka-operator"
    name = "kafka-operator"
    namespace = "kafka"
}