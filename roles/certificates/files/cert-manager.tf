resource "kubernetes_namespace" "ns_cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "rel_cert_manager" {
  namespace = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart = "cert-manager"
  name = "cert-manager"

  set {
      name = "installCRDs"
      value = "true"
  }
}

resource "kubernetes_secret" "sec_ca_pair" {
  metadata {
    namespace = "cert-manager"
    name = "ca-key-pair"
  }
  data = {
    "tls.key" = file("./key.pem")
    "tls.crt" = file("./ca.crt")
  }
}

resource "kubectl_manifest" "mf_cluster_issuer" {
  yaml_body = <<YAML
    apiVersion: cert-manager.io/v1alpha2
    kind: ClusterIssuer
    metadata:
      name: cluster-issuer
      namespace: cert-manager
    spec:
      ca:
        secretName: ca-key-pair
  YAML
  depends_on = [helm_release.rel_cert_manager]
}
