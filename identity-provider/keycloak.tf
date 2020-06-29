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
        name = "persistence.size"
        value = "500Mi"
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
    set {
        name = "metrics.enabled"
        value = "true"
    }

    set {
        name = "metrics.serviceMonitor.enabled"
        value = "true"
    }

    set {
        name = "metrics.serviceMonitor.namespace"
        value = "keycloak"
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

resource "kubectl_manifest" "mf_keycloak_cert" {
  yaml_body = <<YAML
    apiVersion: cert-manager.io/v1alpha2
    kind: Certificate
    metadata:
        name: keycloak-app-cert
        namespace: keycloak
    spec:
        secretName: keycloak-app-tls
        dnsNames:
        - auth.haus.net
        - app-keycloak-http
        - app-keycloak-http.keycloak
        - app-keycloak-http.keycloak.svc
        - app-keycloak-http.keycloak.svc.cluster
        - app-keycloak-http.keycloak.svc.cluster.local
        ipAddresses:
        - 192.168.0.120
        - 127.0.0.1
        issuerRef:
            name: cluster-issuer
            kind: ClusterIssuer
  YAML
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

    # set {
    #     name = "prometheus.operator.enabled"
    #     value = "true"
    # }

    depends_on = [kubectl_manifest.mf_keycloak_cert]
}
