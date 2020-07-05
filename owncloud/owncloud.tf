resource "kubectl_manifest" "mf_owncloud_cert" {
  yaml_body = <<YAML
    apiVersion: cert-manager.io/v1alpha2
    kind: Certificate
    metadata:
        name: owncloud-app-cert
        namespace: owncloud
    spec:
        secretName: owncloud-app-tls
        dnsNames:
        - files.haus.net
        - files-owncloud
        - files-owncloud.owncloud
        - files-owncloud.owncloud.svc
        - files-owncloud.owncloud.svc.cluster
        - files-owncloud.owncloud.svc.cluster.local
        ipAddresses:
        - 192.168.0.120
        - 127.0.0.1
        issuerRef:
            name: cluster-issuer
            kind: ClusterIssuer
  YAML
}

resource "helm_release" "rel_owncloud" {
  repository = "https://charts.bitnami.com/bitnami"
  chart = "owncloud"
  name = "files"
  namespace = "owncloud"

  values = [file("./owncloud.values.yaml")]

  set {
    name = "owncloudHost"
    value = "files.haus.net"
  }
  set {
    name = "owncloudUsername"
    value = "vault:secret/data/owncloud/application/credential#app_user"
  }
  set {
    name = "owncloudPassword"
    value = "vault:secret/data/owncloud/application/credential#app_password"
  }
  set {
    name = "podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-addr"
    value = "https://vault.owncloud:8200"
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
    name = "persistence.enabled"
    value = "true"
  }
  set {
    name = "persistence.owncloud.storageClass"
    value = "nfs-client"
  }
  set {
    name = "persistence.owncloud.size"
    value = "2Ti"
  }
  set {
    name = "service.type"
    value = "ClusterIP"
  }
  set {
    name = "mariadb.db.user"
    value = "vault:secret/data/owncloud/database/credential#db_user"
  }
  set {
    name = "mariadb.db.password"
    value = "vault:secret/data/owncloud/database/credential#db_password"
  }
  set {
    name = "mariadb.master.persistence.enabled"
    value = "true"
  }
  set {
    name = "mariadb.master.persistence.size"
    value = "1Gi"
  }
  set {
    name = "mariadb.master.annotations.vault\\.security\\.banzaicloud\\.io/vault-role"
    value = "default"
  }
  set {
    name = "mariadb.master.annotations.vault\\.security\\.banzaicloud\\.io/vault-addr"
    value = "https://vault.owncloud:8200"
  }
  set {
    name = "mariadb.master.annotations.vault\\.security\\.banzaicloud\\.io/vault-tls-secret"
    value = "vault-tls"
  }
  set {
    name = "mariadb.master.persistence.enabled"
    value = "true"
  }
  set {
    name = "mariadb.master.persistence.size"
    value = "1Gi"
  }
  set {
    name = "mariadb.master.annotations.vault\\.security\\.banzaicloud\\.io/vault-role"
    value = "default"
  }
  set {
    name = "mariadb.master.annotations.vault\\.security\\.banzaicloud\\.io/vault-addr"
    value = "https://vault.owncloud:8200"
  }
  set {
    name = "mariadb.master.annotations.vault\\.security\\.banzaicloud\\.io/vault-tls-secret"
    value = "vault-tls"
  }
}