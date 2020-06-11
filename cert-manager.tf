resource "helm_release" "rel_cert_manager" {
    repository = "https://charts.jetstack.io"
    chart = "cert-manager"
    name = "cert-manager"
    namespace = "cert-manager"
    create_namespace = true

    set {
        name = "installCRDs"
        value = "true"
    }
}

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
    depends_on = [helm_release.rel_cert_manager]
}
