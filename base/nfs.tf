resource "helm_release" "rel_nfs" {
  repository = "https://kubernetes-charts.storage.googleapis.com"
  chart = "nfs-client-provisioner"
  name = "nfs-server"
  namespace = "nas"
  create_namespace = true

  set {
    name = "nfs.server"
    value = "172.16.0.1"
  }
  set {
    name = "nfs.path"
    value = "/mnt/external"
  }
}
