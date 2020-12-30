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
    path = "secret/owncloud/db/credentials"
    data_json = <<JSON
    {
        "db_user": "${ var.db_user }",
        "db_password": "${ var.db_password }"
    }
    JSON
}

resource "vault_generic_secret" "sec_app_creds" {
    path = "secret/owncloud/app/credentials"
    data_json = <<JSON
    {
        "app_user": "${ var.app_user }",
        "app_password": "${ var.app_password }"
    }
    JSON
}

resource "helm_release" "rel_redis" {
  chart = "redis"
  name = "locking"
  namespace = "files"
  repository = "https://charts.bitnami.com/bitnami"

  set {
    name = "password"
    value = var.redis_password
  }
  set {
    name = "cluster.enabled"
    value = "false"
  }
}

resource "helm_release" "rel_database" {
  depends_on = [vault_generic_secret.sec_db_creds]
  repository = "https://charts.bitnami.com/bitnami"
  name = "database"
  namespace = "files"
  chart = "mariadb"

  set {
    name = "auth.database"
    value = "owncloud"
  }

  set {
    name = "auth.password"
    value = "vault:secret/data/owncloud/db/credentials#db_password"
  }

  set {
    name = "auth.username"
    value = "vault:secret/data/owncloud/db/credentials#db_user"
  }

  set {
    name = "primary.podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-addr"
    value = "https://vault.vault-system:8200"
  }

  set {
    name = "primary.podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-tls-secret"
    value = "vault-cert-tls"
  }

  set {
    name = "primary.podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-role"
    value = "default"
  }

  set {
    name = "serviceAccount.create"
    value = "false"
  }

  set {
    name = "secondary.replicaCount"
    value = "0"
  }

  set {
    name = "primary.persistence.enabled"
    value = "true"
  }

  set {
    name = "primary.persistence.storageClass"
    value = "nfs-client"
  }

}

resource "kubernetes_persistent_volume_claim" "pvc_owncloud" {
  metadata {
    name = "owncloud-files"
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

resource "kubernetes_deployment" "dep_owncloud" {
  depends_on = [helm_release.rel_database, vault_generic_secret.sec_app_creds]
  metadata {
    name = "owncloud"
    namespace = "files"
  }
  spec {
    selector {
      match_labels = {
        "app" = "owncloud"
      }
    }
    template {
      metadata {
        annotations = {
          "vault.security.banzaicloud.io/vault-addr" = "https://vault.vault-system:8200"
          "vault.security.banzaicloud.io/vault-tls-secret" = "vault-cert-tls"
          "vault.security.banzaicloud.io/vault-role" = "default"
        }
        labels = {
          "app" = "owncloud"
        }
      }
      spec {
        automount_service_account_token = true
        container {
          name = "owncloud-app"
          image = "owncloud/server:10.6"
          # env {
          #   name = "OWNCLOUD_APPS_INSTALL"
          #   value = "files_pdfviewer,metadata,openidconnect,files_mediaviewer,drawio,activity,camerarawpreviews"
          # }
          env {
            name = "OWNCLOUD_ADMIN_USERNAME"
            value = "vault:secret/data/owncloud/app/credentials#app_user"
          }
          env {
            name = "OWNCLOUD_ADMIN_PASSWORD"
            value = "vault:secret/data/owncloud/app/credentials#app_password"
          }
          env {
            name = "OWNCLOUD_DB_USERNAME"
            value = "vault:secret/data/owncloud/db/credentials#db_user"
          }
          env {
            name = "OWNCLOUD_DB_PASSWORD"
            value = "vault:secret/data/owncloud/db/credentials#db_password"
          }
          env {
            name = "OWNCLOUD_DB_HOST"
            value = "database-mariadb"
          }
          env {
            name = "OWNCLOUD_DB_PORT"
            value = "5432"
          }
          env {
            name = "OWNCLOUD_DB_TYPE"
            value = "mysql"
          }
          env {
            name = "OWNCLOUD_VOLUME_ROOT"
            value = "/mnt/external/owncloud"
          }

          env {
            name = "OWNCLOUD_REDIS_ENABLED"
            value = "true"
          }

          env {
            name = "OWNCLOUD_REDIS_HOST"
            value = "locking-redis-master"
          }

          env {
            name = "OWNCLOUD_REDIS_PASSWORD"
            value = var.redis_password
          }

          port {
            container_port = 8080
          }

          volume_mount {
            name = "owncloud-files"
            mount_path = "/mnt/external/owncloud"
          }
        }
        volume {
          name = "owncloud-files"
          persistent_volume_claim {
            claim_name = "owncloud-files"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "svc_owncloud" {
  metadata {
    name = "owncloud"
    namespace = "files"
    labels = {
      "app" = "owncloud"
    }
  }
  spec {
    selector = {
      "app" = "owncloud"
    }
    port {
      port = 80
      target_port = "8080"
    }
  }
}

resource "kubernetes_ingress" "ing_owncloud" {
  metadata {
    name = "owncloud"
    namespace = "files"
    labels = {
      "app" = "owncloud"
    }
    annotations = {
      "kubernetes.io/ingress-class" = "nginx"
      "cert-manager.io/cluster-issuer" = "cluster-issuer"
      "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
    }
  }
  spec {
    rule {
      host = "files.haus.net"
      http {
        path {
          path = "/"
          backend {
            service_name = "owncloud"
            service_port = "80"
          }
        }
      }
    }
    tls {
      hosts = [ "files.haus.net" ]
      secret_name = "owncloud-cert-tls"
    }
  }
}
