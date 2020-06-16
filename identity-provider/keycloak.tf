resource "helm_release" "rel_keycloak_db" {
    repository = "https://charts.bitnami.com/bitnami"
    chart = "postgresql"
    name = "db"
    namespace = "keycloak"

    set {
        name = "image.tag"
        value = "12"
    }

    set {
        name = "master.podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-addr"
        value = "https://vault.keycloak:8200"
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
        name = "slave.podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-addr"
        value = "https://vault.keycloak:8200"
    }

    set {
        name = "slave.podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-tls-secret"
        value = "vault-tls"
    }

    set {
        name = "slave.podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-role"
        value = "default"
    }

    set {
        name = "global.postgresql.postgresqlUsername"
        value = "vault:secret/data/keycloak/database/credential#db_user"
    }

    set {
        name = "global.postgresql.postgresqlDatabase"
        value = "keycloak"
    }

    set {
        name = "global.postgresql.postgresqlPassword"
        value = "vault:secret/data/keycloak/database/credential#db_password"
    }
}

resource "kubernetes_secret" "sec_keycloak_pwd" {
    metadata {
        name = "keycloak-password"
        namespace = "keycloak"
        annotations = {
            "vault.security.banzaicloud.io/vault-addr" = "https://vault.keycloak:8200"
            "vault.security.banzaicloud.io/vault-role" = "default"
            "vault.security.banzaicloud.io/vault-path" = "kubernetes"
            "vault.security.banzaicloud.io/vault-skip-verify" = "true"
        }
    }
    data = {
        app_password = "vault:secret/data/keycloak/application/credential#app_password"
    }
}

resource "helm_release" "rel_keycloak_app" {
    repository = "https://codecentric.github.io/helm-charts"
    chart = "keycloak"
    namespace = "keycloak"
    name = "app"

    values = [file("./keycloak.values.yaml")]
    set {
        name = "keycloak.persistence.deployPostgres"
        value = "false"
    }

    set {
        name = "keycloak.persistence.dbVendor"
        value = "postgres"
    }
    set {
        name = "keycloak.persistence.dbName"
        value = "keycloak"
    }
    set {
        name = "keycloak.persistence.dbUser"
        value = "vault:secret/data/keycloak/database/credential#db_user"
    }
    set {
        name = "keycloak.persistence.dbPassword"
        value = "vault:secret/data/keycloak/database/credential#db_password"
    }
    set {
        name = "keycloak.persistence.dbHost"
        value = "db-postgresql"
    }
    set {
        name = "keycloak.username"
        value = "vault:secret/data/keycloak/application/credential#app_user"
    }
    set {
        name = "keycloak.existingSecret"
        value = "keycloak-password"
    }

    set {
        name = "keycloak.existingSecretKey"
        value = "app_password"
    }
    # set {
    #     name = "keycloak.password"
    #     value = "vault:secret/data/keycloak/application/credential#app_password"
    # }
    set {
        name = "keycloak.podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-addr"
        value = "https://vault.keycloak:8200"
    }
    set {
        name = "keycloak.podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-role"
        value = "default"
    }

    set {
        name = "keycloak.podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-tls-secret"
        value = "vault-tls"
    }
}
