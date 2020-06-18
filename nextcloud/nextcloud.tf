resource "helm_release" "rel_nextcloud_db" {
  repository = "https://charts.bitnami.com/bitnami"
  chart = "mariadb"
  name = "db"
  namespace = "nextcloud"

  values = [file("./db.values.yaml")]
}

resource "kubernetes_persistent_volume_claim" "pvc_nextcloud" {
  metadata {
    name = "nextcloud-storage"
    namespace = "nextcloud"
  }
  spec {
    access_modes = ["ReadWriteMany"]
    storage_class_name = "nfs"
    resources {
      requests = {
        "storage" = "5Gi"
      }
    }
  }
}

resource "kubectl_manifest" "mf_keycloak_cert" {
  yaml_body = <<YAML
    apiVersion: cert-manager.io/v1alpha2
    kind: Certificate
    metadata:
        name: nextcloud-app-cert
        namespace: nextcloud
    spec:
        secretName: nextcloud-app-tls
        dnsNames:
        - files.haus.net
        - nextcloud
        - nextcloud.owncloud
        - nextcloud.owncloud.svc
        - nextcloud.owncloud.svc.cluster
        - nextcloud.owncloud.svc.cluster.local
        ipAddresses:
        - 192.168.0.120
        - 127.0.0.1
        issuerRef:
            name: cluster-issuer
            kind: ClusterIssuer
  YAML
}

resource "helm_release" "rel_nextcloud" {
  repository = "https://kubernetes-charts.storage.googleapis.com"
  chart = "nextcloud"
  name = "app"
  namespace = "nextcloud"

  values = [file("./nextcloud.values.yaml")]

  set {
    name = "nextcloud.host"
    value = "files.haus.net"
  }
  set {
    name = "nextcloud.username"
    value = "vault:secret/data/nextcloud/application/credential#app_user"
  }
  set {
    name = "nextcloud.password"
    value = "vault:secret/data/nextcloud/application/credential#app_password"
  }
  set {
    name = "podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-addr"
    value = "https://vault.nextcloud:8200"
  }
  set {
    name = "podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-tls-secret"
    value = "vault-tls"
  }
  set {
    name = "podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-role"
    value = "default"
  }
  set {
    name = "internalDatabase.enabled"
    value = "false"
  }
  set {
    name = "externalDatabase.user"
    value = "vault:secret/data/nextcloud/database/credential#db_user"
  }
  set {
    name = "externalDatabase.password"
    value = "vault:secret/data/nextcloud/database/credential#db_password"
  }
  set {
    name = "externalDatabase.enabled"
    value = "true"
  }
  set {
    name = "externalDatabase.host"
    value = "db-mariadb"
  }
  set {
    name = "externalDatabase.database"
    value = "nextcloud"
  }
  set {
    name = "persistence.enabled"
    value = "true"
  }
  set {
    name = "persistence.existingClaim"
    value = "nextcloud-storage"
  }
  depends_on = [helm_release.rel_nextcloud_db]
}