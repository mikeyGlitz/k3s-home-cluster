resource "kubernetes_namespace" "ns_keycloak" {
    metadata {
        name = "keycloak"
        annotations = {
            "linkerd.io/inject" = "enabled"
        }
    }
}

resource "kubernetes_secret" "sec_realm" {
  metadata {
    name = "keycloak-hausnet-realm"
    namespace = "keycloak"
  }

  data = {
    "hausnet.json" = file("./realm.json")
  }
}

resource "kubectl_manifest" "mf_https_config" {
  yaml_body = <<YAML
  apiVersion: configuration.konghq.com/v1
  kind: KongIngress
  metadata:
      name: https-only
      namespace: keycloak
  route:
    protocols:
    - https
    https_redirect_status_code: 302
  YAML
}

resource "helm_release" "rel_keycloak" {
    namespace = "keycloak"
    name = "keycloak"
    repository = "https://codecentric.github.io/helm-charts"
    chart = "keycloak"

    depends_on = [
        vault_generic_secret.sec_keycloak_db,
        vault_generic_secret.sec_keycloak_app
    ]

    values = [
        <<YAML
            ingress:
              enabled: true
              annotations:
                kubernetes.io/ingress.class: kong
                cert-manager.io/cluster-issuer: cluster-issuer
                konghq.com/override: "https-only"
              rules:
                - host: auth.haus.net
                  paths:
                    - /
              tls:
                - hosts:
                    - auth.haus.net
                  secretName: keycloak-app-tls
            podAnnotations:
              vault.security.banzaicloud.io/vault-addr: https://vault.vault-system:8200
              vault.security.banzaicloud.io/vault-tls-secret: vault-cert-tls
              vault.security.banzaicloud.io/vault-role: default
            extraEnv: |
              - name: PROXY_ADDRESS_FORWARDING
                value: "true"
              - name: KEYCLOAK_USER
                value: vault:secret/data/keycloak/application/credential#app_user
              - name: KEYCLOAK_PASSWORD
                value: vault:secret/data/keycloak/application/credential#app_password
              - name: KEYCLOAK_IMPORT
                value: /secrets/realms/hausnet.json
            extraVolumeMounts: |
              - name: realms
                mountPath: /secrets/realms
            extraVolumes: |
              - name: realms
                secret:
                  secretName: keycloak-hausnet-realm
        YAML
    ]

    set {
      name = "serviceAccount.create"
      value = "false"
    }

    set {
        name = "postgresql.enabled"
        value = "true"
    }

    set { 
        name = "postgresql.postgresqlUsername"
        value = "vault:secret/data/keycloak/database/credential#database_user"
    }

    set { 
        name = "postgresql.postgresqlPassword"
        value = "vault:secret/data/keycloak/database/credential#database_password"
    }

    set { 
        name = "postgresql.postgresqlDatabase"
        value = "keycloak"
    }

    set {
        name = "postgresql.persistence.storageClass"
        value = "nfs-client"
    }

    set {
        name = "postgresql.master.podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-addr"
        value = "https://vault.vault-system:8200"
    }
    set {
        name = "postgresql.master.podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-tls-secret"
        value = "vault-cert-tls"
    }
    set {
        name = "postgresql.master.podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-role"
        value = "default"
    }
}
