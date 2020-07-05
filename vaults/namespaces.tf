resource "kubernetes_namespace" "ns_keycloak" {
  metadata {
    name = "keycloak"
    annotations = {
      "linkerd.io/inject" = "enabled"
    }
  }
}

resource "kubernetes_namespace" "ns_owncloud" {
  metadata {
    name = "owncloud"
    annotations = {
      "linkerd.io/inject" = "enabled"
    }
  }
}
resource "kubernetes_namespace" "ns_ldap" {
  metadata {
    name = "ldap"
    annotations = {
      "linkerd.io/inject" = "enabled"
    }
  }
}

resource "kubernetes_namespace" "ns_logging" {
  metadata {
    name = "logging"
    annotations = {
      "linkerd.io/inject": "enabled"
    }
  }
}
