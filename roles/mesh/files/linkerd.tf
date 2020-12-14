resource "kubernetes_namespace" "ns_linkerd" {
  metadata {
    name = "linkerd"
  }
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
        name: cluster-issuer
        kind: ClusterIssuer
      commonName: identity.linkerd.cluster.local
      isCA: true
      keyAlgorithm: ecdsa
      usages:
      - cert sign
      - crl sign
      - server auth
      - client auth
  YAML
  provisioner "local-exec" {
    command = ".linkerd2/bin/linkerd --identity-external-issuer=true --config config.yml | kubectl apply -f -"
  }
}