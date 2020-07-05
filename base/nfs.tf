resource "kubernetes_namespace" "ns_nfs" {
  metadata {
    name = "nas"
    annotations = {
      "linkerd.io/inject" = "enabled"
    }
  }
}

resource "helm_release" "rel_nfs" {
  repository = "https://kubernetes-charts.storage.googleapis.com"
  chart = "nfs-client-provisioner"
  name = "nfs-server"
  namespace = "nas"

  values = [
    <<YAML
      nfs:
        mountOptions:
        - nfsvers=4
    YAML
  ]

  set {
    name = "nfs.server"
    value = "172.16.0.1"
  }
  set {
    name = "nfs.path"
    value = "/mnt/external"
  }
}
