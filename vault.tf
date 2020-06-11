# variable "docker_user" {
#     type = string
# }

# variable "docker_password" {
#     type = string
# }

# variable "docker_email" {
#     type = string
# }

# data "template_file" "tmp_dockerconfig" {
#     template = file("./dockerconfig.json")
#     vars = {
#         username = var.docker_user
#         password = var.docker_password
#         email = var.docker_email
#     }
# }

resource "kubernetes_namespace" "ns_vault" {
    metadata {
        name = "vault-infra"
        labels = {
            name = "vault-infra"
        }
    }
}

resource "kubectl_manifest" "mf_vault_cert" {
    yaml_body = <<YAML
        apiVersion: cert-manager.io/v1alpha2
        kind: Certificate
        metadata:
          name: vault-cert
          namespace: vault-infra
        spec:
          secretName: vault-cert-tls
          commonName: vault
          usages:
          - server auth
          dnsNames:
          - vault
          - vault.default
          - vault.default.svc
          - vault.default.svc.cluster
          - vault.default.svc.cluster.local
          ipAddresses:
          - 127.0.0.1
          - 192.168.0.120
          issuerRef:
            name: cluster-issuer
            kind: ClusterIssuer
    YAML
}

resource "helm_release" "rel_vault_operator" {
    repository = "https://kubernetes-charts.banzaicloud.com"
    chart = "vault-operator"
    name = "vault-operator"
    namespace = "vault-infra"
    depends_on = [kubectl_manifest.mf_vault_cert]

    set {
        name = "tls.secretName"
        value = "vault-cert-tls"
    }
}

# resource "kubernetes_secret" "sec_docker_repo" {
#     metadata {
#         name = "docker-registry"
#         namespace = "vault-infra"
#     }
#     type = "kubernetes.io/dockerconfigjson"
#     data = {
#         ".dockerconfigjson" = data.template_file.tmp_dockerconfig.rendered
#     }
# }

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

    # set {
    #     name = "env.DEFAULT_IMAGE_PULL_SECRET"
    #     value = "docker-registry"
    # }

    # set {
    #     name = "env.DEFAULT_IMAGE_PULL_SECRET_NAMESPACE"
    #     value = "vault-infra"
    # }

    # depends_on = [kubernetes_secret.sec_docker_repo, kubectl_manifest.mf_cert_issuer]
    depends_on = [kubectl_manifest.mf_cert_issuer]
}
