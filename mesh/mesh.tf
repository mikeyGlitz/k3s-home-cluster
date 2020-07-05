resource "kubernetes_namespace" "ns_linkerd" {
    metadata {
        name = "linkerd"
    }
}

resource "kubernetes_secret" "sec_trust_anchor" {
    metadata {
        name = "linkerd-trust-anchor"
        namespace = "linkerd"
    }
    data = {
        "tls.crt" = file("./ca.crt")
        "tls.key" = file("./key.pem")
    }
}

resource "kubectl_manifest" "mf_linkerd_issuer" {
    yaml_body = <<YAML
    apiVersion: cert-manager.io/v1alpha2
    kind: Issuer
    metadata:
      name: linkerd-issuer
      namespace: linkerd
    spec:
      ca:
        secretName: linkerd-trust-anchor
    YAML
}

resource "kubectl_manifest" "mf_linkerd_cert" {
    yaml_body = <<YAML
    apiVersion: cert-manager.io/v1alpha2
    kind: Certificate
    metadata:
      name: linkerd-identity-issuer
      namespace: linkerd
    spec:
      secretName: linkerd-identity-issuer
      duration: 24h
      renewBefore: 1h
      issuerRef:
        name: linkerd-issuer
        kind: Issuer
      commonName: identity.linkerd.cluster.local
      isCA: true
      keyAlgorithm: ecdsa
      usages:
      - cert sign
      - crl sign
      - server auth
      - client auth
    YAML
}