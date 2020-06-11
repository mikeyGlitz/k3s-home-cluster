data "template_file" "temp_keycloak_vault" {
    template = file("./vault.yaml")
    vars = {
        namespace = "keycloak"
        account = "keycloak"
    }
}

# Resources

resource "kubernetes_namespace" "ns_keycloak" {
    metadata {
        name = "keycloak"
        labels = {
            name = "keycloak"
        }
    }
}


resource "kubernetes_service_account" "sa_keycloak" {
    metadata {
        name = "keycloak"
        namespace = "keycloak"
    }
    automount_service_account_token = true
}

resource "kubernetes_role" "role_keycloak" {
    metadata {
        name = "vault-secrets"
        namespace = "keycloak"
    }
    rule {
        api_groups = [""]
        resources = [ "secrets" ]
        verbs = ["*"]
    }
}

resource "kubernetes_role_binding" "rb_keycloak" {
    metadata {
        name = "vault-secrets"
        namespace = "keycloak"
    }
    role_ref {
        api_group = "rbac.authorization.k8s.io"
        kind = "Role"
        name = "vault-secrets"
    }

    subject {
        kind = "ServiceAccount"
        name = "keycloak"
        namespace = "keycloak"
    }
}

resource "kubernetes_cluster_role_binding" "crb_keycloak" {
    metadata {
        name = "vault-auth-delegator"
    }
    role_ref {
        api_group = "rbac.authorization.k8s.io"
        kind = "ClusterRole"
        name = "system:auth-delegator"
    }

    subject {
        kind = "ServiceAccount"
        name = "keycloak"
        namespace = "keycloak"
    }
}

resource "kubectl_manifest" "mf_keycloak_vault" {
    yaml_body = data.template_file.temp_keycloak_vault.rendered
    depends_on = [
        helm_release.rel_vault_operator
    ]
}

resource "kubernetes_secret" "sec_db_pwd" {
    metadata {
      name = "db-secret"
      namespace = "keycloak"
      annotations = {
        "vault.security.banzaicloud.io/vault-addr" = "https://vault.keycloak:8200"
        "vault.security.banzaicloud.io/vault-role" = "default"
        "vault.security.banzaicloud.io/vault-skip-verify" = "true"
        "vault.security.banzaicloud.io/vault-path" = "kubernetes"
      }
    }
    data = {
      "postgresql-password" = "vault:secret/data/keycloak/database/credential#db_password"
    }
}

resource "helm_release" "rel_keycloak_db" {
    repository = "https://charts.bitnami.com/bitnami"
    chart = "postgresql"
    name = "db"
    namespace = "keycloak"

    set {
        name = "master.podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-addr"
        value = "https://vault.keycloak:8200"
    }

    set {
        name = "master.podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-tls-secret"
        value = "vault-tls"
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
        name = "postgresqlUsername"
        value = "vault:secret/data/keycloak/database/credential#db_user"
    }

    set {
        name = "postgresqlPostgresPassword"
        value = "vault:secret/data/keycloak/database/credential#db_password"
    }

    set {
        name = "postgresqlPassword"
        value = "vault:secret/data/keycloak/database/credential#db_password"
    }

    # set {
    #     name = "existingSecret"
    #     value = "db-secret"
    # }

    # set {
    #     name = "postgresqlDatabase"
    #     value = "keycloak"
    # }

    # set {
    #     name = "postgresqlUsername"
    #     value = "keycloak"
    # }

    depends_on = [kubernetes_secret.sec_db_pwd]
}

resource "kubectl_manifest" "mf_keycloak_app_cert" {
    yaml_body = <<YAML
        apiVersion: cert-manager.io/v1alpha2
        kind: Certificate
        metadata:
          name: keycloak-cert
          namespace: keycloak
        spec:
          secretName: app-cert-tls
          commonName: auth
          usages:
          - server auth
          dnsNames:
          - app
          - app.keycloak
          - app.keycloak.svc
          - app.keycloak.svc.cluster
          - app.keycloak.svc.cluster.local
          - auth.haus.net
          ipAddresses:
          - 127.0.0.1
          - 192.168.0.120
          issuerRef:
            name: cluster-issuer
            kind: ClusterIssuer
    YAML
    depends_on = [kubectl_manifest.mf_cert_issuer]
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
        name = "keycloak.password"
        value = "vault:secret/data/keycloak/application/credential#app_password"
    }
    set {
        name = "keycloak.podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-addr"
        value = "https://vault.keycloak:8200"
    }

    set {
        name = "keycloak.podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-tls-secret"
        value = "vault-tls"
    }

    depends_on = [kubectl_manifest.mf_keycloak_vault, helm_release.rel_vault_webhook]
}
