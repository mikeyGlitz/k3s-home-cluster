resource "kubernetes_namespace" "ns_mailu"{
    metadata {
        name = "mailu"
    }
}

resource "helm_release" "rel_mailu_db" {
    repository = "https://charts.bitnami.com/bitnami"
    chart = "mariadb"
    name = "db"
    namespace = "mailu"

    set {
        name = "master.persistence.size"
        value = "2Gi"
    }

    set {
        name = "slave.persistence.size"
        value = "2Gi"
    }

    set {
        name = "db.user"
        value = var.database_user
    }

    set {
        name = "db.name"
        value = "mailu"
    }

    set {
        name = "db.password"
        value = var.database_password
    }
}

resource "random_uuid" "rand_enc_key" {}

resource "helm_release" "rel_mailu" {
  repository = "https://mailu.github.io/helm-charts/"
  chart = "mailu"
  name = "mail"
  namespace = "mailu"

  values = [file("./values.yaml")]

  set {
      name = "persistence.storageClass"
      value = "nfs-client"
  }

#   set {
#       name = "persistence.size"
#       value = "10Gi"
#   }

  set {
      name = "clamav.enabled"
      value = "false"
  }
  set {
      name = "initialAccount.domain"
      value = "haus.net"
  }

  set {
      name = "initialAccount.username"
      value = var.mailu_user
  }

  set {
      name = "initialAccount.password"
      value = var.mailu_password
  }

  set {
      name = "secretKey"
      value = random_uuid.rand_enc_key.result
  }

  set {
      name = "database.type"
      value = "mysql"
  }

  set {
      name = "database.mysql.user"
      value = var.database_user
  }
  
  set {
      name = "database.mysql.password"
      value = var.database_password
  }

  set {
      name = "database.mysql.host"
      value = "db-mariadb"
  }

  set {
      name = "database.mysql.database"
      value = "mailu"
  }

  set {
      name = "certmanager.issuerName"
      value = "cluster-issuer"
  }

  set {
      name = "certmanager.issuerType"
      value = "ClusterIssuer"
  }

  depends_on = [helm_release.rel_mailu_db]
}