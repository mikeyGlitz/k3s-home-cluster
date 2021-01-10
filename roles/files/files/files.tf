variable "db_password" {
    type = string
    description = "(optional) describe your variable"
}
variable "db_user" {
    type = string
    default = "files_manager"
    description = "(optional) describe your variable"
}

variable "app_user" {
    type = string
    default = "manager"
    description = "(optional) describe your variable"
}

variable "app_password" {
    type = string
    description = ""
}

variable "redis_password" {
    type = string
    description = ""
}

resource "vault_generic_secret" "sec_db_creds" {
    path = "secret/nextcloud/db/credentials"
    data_json = <<JSON
    {
        "db_user": "${ var.db_user }",
        "db_password": "${ var.db_password }"
    }
    JSON
}

resource "vault_generic_secret" "sec_app_creds" {
    path = "secret/nextcloud/app/credentials"
    data_json = <<JSON
    {
        "app_user": "${ var.app_user }",
        "app_password": "${ var.app_password }"
    }
    JSON
}

resource "kubernetes_persistent_volume_claim" "pvc_files" {
  metadata {
    name = "files"
    namespace = "files"
  }
  spec {
    storage_class_name = "nfs-client"
    access_modes = [ "ReadWriteMany" ]
    resources {
      requests = {
        "storage" = "2.5Ti"
      }
    }
  }
}

resource "helm_release" "rel_files_cloud" {
  repository = "https://nextcloud.github.io/helm/"
  name="cloudfiles"
  chart = "nextcloud"
  namespace="files"

  values = [
      <<YAML
        ingress:
          enabled: true
          annotations:
            kubernetes.io/ingress-class: nginx
            cert-manager.io/cluster-issuer: cluster-issuer
            nginx.ingress.kubernetes.io/ssl-redirect: 'true'
            nginx.ingress.kubernetes.io/proxy-body-size: 2g
          tls:
            - hosts:
              - files.haus.net
              secretName: nextcloud-app-tls
      YAML
   ]

  set {
    name = "nextcloud.host"
    value = "files.haus.net"
  }

  set {
      name = "nextcloud.username"
      value = "vault:secret/data/nextcloud/app/credentials#app_user"
  }
  set {
      name = "nextcloud.password"
      value = "vault:secret/data/nextcloud/app/credentials#app_password"
  }
  set {
      name = "internalDatabase.enabled"
      value = "false"
  }
  set {
      name = "mariadb.enabled"
      value = "true"
  }
  set {
      name = "mariadb.db.password"
      value = "vault:secret/data/nextcloud/db/credentials#db_password"
  }
  set {
      name = "mariadb.db.user"
      value = "vault:secret/data/nextcloud/db/credentials#db_user"
  }
  set {
      name = "mariadb.master.persistence.storageClass"
      value = "nfs-client"
  }
  set {
      name = "mariadb.master.annotations.vault\\.security\\.banzaicloud\\.io/vault-addr"
      value = "https://vault.vault-system:8200"
  }
  set {
      name = "mariadb.master.annotations.vault\\.security\\.banzaicloud\\.io/vault-tls-secret"
      value = "vault-cert-tls"
  }
  set {
      name = "mariadb.master.annotations.vault\\.security\\.banzaicloud\\.io/vault-role"
      value = "default"
  }
  set {
      name = "persistence.enabled"
      value = "true"
  }
  set {
      name = "persistence.existingClaim"
      value = "files"
  }

  set {
      name = "podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-addr"
      value = "https://vault.vault-system:8200"
  }
  set {
      name = "podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-tls-secret"
      value = "vault-cert-tls"
  }
  set {
      name = "podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-role"
      value = "default"
  }
  set {
      name = "livenessProbe.enabled"
      value ="false"
  }

  set {
      name = "readinessProbe.enabled"
      value ="false"
  }

  set {
      name = "redis.enabled"
      value = "true"
  }

  set {
      name = "redis.password"
      value = var.redis_password
  }

  set {
      name = "redis.usePassword"
      value = "true"
  }
}
