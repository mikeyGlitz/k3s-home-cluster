resource "kubernetes_namespace" "ns_keycloak" {
  metadata {
    name = "keycloak"
  }
}

resource "kubernetes_namespace" "ns_owncloud" {
  metadata {
    name = "owncloud"
  }
}
resource "kubernetes_namespace" "ns_ldap" {
  metadata {
    name = "ldap"
  }
}
