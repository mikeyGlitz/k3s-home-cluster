resource "kubernetes_namespace" "ns_nginx" {
  metadata {
      name = "ingress-nginx"
  }
}

resource "helm_release" "rel_ing_nginx" {
  name = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart = "ingress-nginx"
  namespace = "ingress-nginx"
  wait = "false"
}

