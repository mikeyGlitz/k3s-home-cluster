resource "kubernetes_namespace" "ns_vault_system" {
  metadata {
    name = "vault-system"
    annotations = {
      "linkerd.io/inject" = "enabled"
    }
  }
}

resource "helm_release" "rel_vault_operator" {
  repository = "https://kubernetes-charts.banzaicloud.com"
  chart = "vault-operator"
  name = "vault-operator"
  namespace = "vault-system"
}

resource "helm_release" "rel_vault_webhook" {
  repository = "https://kubernetes-charts.banzaicloud.com"
  chart = "vault-secrets-webhook"
  name = "vault-secrets-webhook"
  namespace = "vault-system"

  set {
      name = "certificate.generate"
      value = "false"
  }

  set {
      name = "certificate.useCertManager"
      value = "true"
  }
}
