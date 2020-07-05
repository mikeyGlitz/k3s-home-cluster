resource "kubernetes_namespace" "ns_vault" {
    metadata {
        name = "vault-infra"
        labels = {
            name = "vault-infra"
        }
    }
}

resource "helm_release" "rel_vault_operator" {
    repository = "https://kubernetes-charts.banzaicloud.com"
    chart = "vault-operator"
    name = "vault-operator"
    namespace = "vault-infra"
    version = "1.3.2"
}

resource "helm_release" "rel_vault_webhook" {
    repository = "https://kubernetes-charts.banzaicloud.com"
    chart = "vault-secrets-webhook"
    name = "vault-secrets-webhook"
    namespace = "vault-infra"

    set {
        name = "certificate.generate"
        value = "false"
    }
    set {
        name = "certificate.useCertManager"
        value = "true"
    }
    version = "1.3.2"
}
