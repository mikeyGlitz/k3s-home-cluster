resource "kubernetes_namespace" "ns_keycloak" {
    metadata {
        name = "keycloak"
        annotations = {
            "linkerd.io/inject" = "enabled"
        }
    }
}

resource "helm_release" "rel_keycloak_db" {
    repository = "https://charts.bitnami.com/bitnami"
    chart = "postgresql"
    name = "iam-db"
    namespace = "keycloak"

    set {
        name = "master.podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-addr"
        value = "https://vault.vault-system:8200"
    }
    set {
        name = "master.podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-tls-secret"
        value = "vault-tls"
    }
    set {
        name = "master.podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-role"
        value = "default"
    }

    set { 
        name = "postgresqlUsername"
        value = "vault:secret/data/keycloak/database/credential#database_user"
    }

    set { 
        name = "postgresqlPassword"
        value = "vault:secret/data/keycloak/database/credential#database_password"
    }

    set { 
        name = "postgresqlDatabase"
        value = "keycloak"
    }

    set {
        name = "persistence.storageClass"
        value = "nfs-client"
    }

    depends_on = [
        vault_generic_secret.sec_keycloak_db,
        vault_generic_secret.sec_keycloak_app
    ]
}

resource "kubernetes_secret" "sec_keycloak_pwd" {
    metadata {
        name = "keycloak-credentials"
        namespace = "keycloak"
        annotations = {
            "vault.security.banzaicloud.io/vault-addr" = "https://vault.vault-system:8200"
            "vault.security.banzaicloud.io/vault-role" = "default"
            "vault.security.banzaicloud.io/vault-path" = "kubernetes"
            "vault.security.banzaicloud.io/vault-skip-verify" = "true"
        }
    }
    data = {
        app_user = "vault:secret/data/keycloak/application/credential#app_user"
        app_password = "vault:secret/data/keycloak/application/credential#app_password"
        db_user = "vault:secret/data/keycloak/database/credential#database_user"
        db_password = "vault:secret/data/keycloak/database/credential#database_password"
    }
    depends_on = [
        vault_generic_secret.sec_keycloak_db,
        vault_generic_secret.sec_keycloak_app
    ]
}

resource "helm_release" "rel_keycloak" {
    namespace = "keycloak"
    name = "keycloak"
    repository = "https://codecentric.github.io/helm-charts"
    chart = "keycloak"

    depends_on = [
        vault_generic_secret.sec_keycloak_db,
        vault_generic_secret.sec_keycloak_app,
        kubernetes_secret.sec_keycloak_pwd
    ]

    values = [
        <<YAML
            ingress:
            enabled: true
            annotations:
                kubernetes.io/ingress.class: traefik
                cert-manager.io/cluster-issuer: cluster-issuer
                traefik.ingress.kubernetes.io/redirect-entry-point: https
            rules:
                - host: auth.haus.net
                paths:
                    - /
            tls:
                - hosts:
                    - auth.haus.net
                secretName: keycloak-app-tls
            extraEnv: |
              - name: KEYCLOAK_USER_FILE
                value: /secrets/credential/app_user
              - name: KEYCLOAK_USER_PASSWORD
                value: /secrets/credential/app_password
              - name: DB_VENDOR
                value: postgres
              - name: DB_ADDR
                value: iam-db-postgresql
              - name: DB_USER_FILE
                value: /secrets/credential/db_user
              - name: DB_USER_PASSWORD
                value: /secrets/credential/db_password
            extraVolumeMounts: |
              - name: credential
                mountPath: /secrets/db-creds
                readOnly: "true"
            extraVolumes: |
              - name: credential
                secret:
                  secretName: keycloak-credentials
        YAML
    ]

    set {
        name = "postgresql.enabled"
        value = "false"
    }

    set {
        name = "image.tag"
        value = "9.0.0"
    }
}
