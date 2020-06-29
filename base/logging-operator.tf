resource "helm_release" "rel_logging_operator" {
  repository = "https://kubernetes-charts.banzaicloud.com"
  chart = "logging-operator"
  name = "logging"
  namespace = "logging"
  create_namespace = "true"

  set {
    name = "createCustomResource"
    value = "false"
  }
}