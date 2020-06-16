resource "kubernetes_namespace" "ns_cert_manager" {
    metadata {
        name = "cert-manager"
    }
}

resource "helm_release" "rel_cert_manager" {
    repository = "https://charts.jetstack.io"
    chart = "cert-manager"
    name = "cert-manager"
    namespace = "cert-manager"

    set {
        name = "installCRDs"
        value = "true"
    }
}

# resource "kubectl_manifest" "mf_cert_manager" {
#     yaml_body = file("./cert-manager.yaml")
# }

resource "kubernetes_secret" "sec_ca_pair" {
    metadata {
        namespace = "cert-manager"
        name = "ca-pair"
    }
    data = {
        "tls.crt" = file("./certificate.pem")
        "tls.key" = file("./key.pem")
    }
}

resource "kubectl_manifest" "mf_cert_issuer" {
    yaml_body = <<YAML
        apiVersion: cert-manager.io/v1alpha2
        kind: ClusterIssuer
        metadata:
          name: cluster-issuer
          namespace: cert-manager
        spec:
          ca:
            secretName: ca-pair
    YAML
    depends_on = [helm_release.rel_cert_manager, kubernetes_secret.sec_ca_pair]
}
