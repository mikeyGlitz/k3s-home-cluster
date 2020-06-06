resource "kubernetes_namespace" "ns_cert" {
  metadata {
      name = "cert-manager"
  }
}

resource "helm_release" "rel_cert" {
  name = "cert-manager"
  repository = "https://charts.jetstack.io"
  namespace = "cert-manager"
  chart = "cert-manager"
  set {
      name = "installCRDs"
      value = "true"
  }
}

resource "kubectl_manifest" "cluster_issuer" {
  yaml_body = <<YAML
    apiVersion: cert-manager.io/v1alpha2
    kind: ClusterIssuer
    metadata:
      name: cluster-issuer
      namespace: cert-manager
    spec:
      selfsigned: {}
  YAML
  depends_on = [helm_release.rel_cert]
}

