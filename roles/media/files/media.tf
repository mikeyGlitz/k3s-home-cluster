variable "ssh_password" {
    type = string
    description = "Password for SSH users"
}

variable "ssh_user" {
    type = string
    default = "plex"
    description = "SSH Username"
}

variable "plex_token" {
    type = string
    description = "Plex registration token"
}

resource "kubernetes_persistent_volume_claim" "pvc_media" {
  metadata {
      name = "media-datastore"
      namespace = "files"
  }
  spec {
    storage_class_name = "nfs-client"
    access_modes = [ "ReadWriteMany" ]
    resources {
      requests = {
        "storage" = "1Ti"
      }
    }
  }
}

resource "helm_release" "rel_sftp" {
  repository = "https://emberstack.github.io/helm-charts"
  name = "media-filestore"
  namespace = "files"
  chart = "sftp"
  values = [
      <<YAML
        podSecurityContext:
          fsGroup: 1000
        storage:
          volumes:
            - name: media-volume
              persistentVolumeClaim:
                claimName: media-datastore
          volumeMounts:
            - name: media-volume
              mountPath: "/home/${var.ssh_user}/sftp"
        configuration:
          Users:
            - Username: ${var.ssh_user}
              Password: ${var.ssh_password}
              Directories:
                - sftp/Music
                - sftp/Pictures
                - sftp/Videos
      YAML
    ]
}

resource "helm_release" "rel_plex" {
  chart = "plex"
  name = "plex"
  namespace = "files"
  repository = "https://k8s-at-home.com/charts/"

  values = [ 
      <<YAML
      ingress:
        enabled: true
        annotations:
          kubernetes.io/ingress-class: nginx
          cert-manager.io/cluster-issuer: cluster-issuer
          nginx.ingress.kubernetes.io/ssl-redirect: "true"
        hosts:
          - media.haus.net
        tls:
          - secretName: media-cert-tls
            hosts:
              - media.haus.net
        allowedNetworks:
          - 192.168.0.0/24
          - 127.0.0.1
          - 172.16.0.0/27
          - 10.54.2.0/24
      YAML
   ]

  set {
    name = "claimToken"
    value = var.plex_token
  }

  set {
    name = "timezone"
    value = "America/New York"
  }

  set {
    name = "podSecurityContext.fsGroup"
    value = "1000"
  }

  set {
    name = "persistence.data.enabled"
    value = "true"
  }

  set {
    name = "persistence.data.claimName"
    value = "media-datastore"
  }
}