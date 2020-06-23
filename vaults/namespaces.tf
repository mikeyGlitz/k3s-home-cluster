resource "kubernetes_namespace" "ns_keycloak" {
  metadata {
    name = "keycloak"
  }
}

resource "kubernetes_namespace" "ns_nextcloud" {
  metadata {
    name = "nextcloud"
  }
}
resource "kubernetes_namespace" "ns_ldap" {
  metadata {
    name = "ldap"
  }
}
