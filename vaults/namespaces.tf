resource "kubernetes_namespace" "ns_keycloak" {
  metadata {
    name = "keycloak"
  }
}
