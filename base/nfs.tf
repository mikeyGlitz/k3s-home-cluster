resource "kubernetes_namespace" "ns_nfs" {
  metadata {
    name = "nfs"
  }
}

resource "kubectl_manifest" "mf_pv_nfs" {
  yaml_body = <<YAML
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: data-nfs-server-provisioner-0
    spec:
      capacity:
        storage: 800Gi
      accessModes:
      - ReadWriteOnce
      hostPath:
        path: /mnt/external
      claimRef:
        namespace: nfs
        name: data-nfs-server-nfs-server-provisioner-0
  YAML
}

resource "helm_release" "rel_nfs" {
  repository = "https://kubernetes-charts.storage.googleapis.com"
  chart = "nfs-server-provisioner"
  name = "nfs-server"
  namespace = "nfs"

  values = [file("./nfs.values.yaml")]

  set {
    name = "persistence.enabled"
    value = "true"
  }
  set {
    name = "persistence.size"
    value = "800Gi"
  }
  set {
    name = "persistence.storageClass"
    value = "-"
  }
}
