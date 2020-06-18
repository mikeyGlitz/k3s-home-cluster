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
