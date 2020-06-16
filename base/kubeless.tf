data "http" "http_kubeless_ui_mf" {
    url = "https://raw.githubusercontent.com/kubeless/kubeless-ui/master/k8s.yaml"
}

resource "kubernetes_namespace" "ns_kubeless" {
  metadata {
    name = "kubeless"
  }
}

resource "kubectl_manifest" "mf_kubeless" {
  yaml_body = file("./kubeless.yaml")
}

resource "kubectl_manifest" "mf_kubeless_ui" {
  yaml_body = data.http.http_kubeless_ui_mf.body
}
