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

    depends_on = [kubectl_manifest.mf_cert_issuer]
}
