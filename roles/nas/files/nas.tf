resource "kubernetes_namespace" "ns_nfs" {
    metadata {
        name = "nfs"
        annotations = {
            "linkerd.io/inject" = "enabled"
        }
    }
}

resource "helm_release" "rel_nfs" {
    repository = "https://kubernetes-charts.storage.googleapis.com/"
    chart = "nfs-client-provisioner"
    name ="nfs-client"
    namespace = "nfs"
    create_namespace = true

    values = [
        <<YAML
            nfs:
              mountOptions:
                - nfsvers=4
                - async
                - noatime
        YAML
    ]

    set {
        name = "nfs.server"
        value = "192.168.0.120"
    }

    set {
        name = "nfs.path"
        value = "/mnt/external"
    }
}