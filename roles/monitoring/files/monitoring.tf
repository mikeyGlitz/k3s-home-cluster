variable "client_secret" {
    type = string
    description = "Keycloak client secret"
}

variable "client_id" {
    type = string
    description = "Keycloak client id"
}

variable "encryption_key" {
    type = string
    description = "Cookie encryption key"
}

resource "vault_generic_secret" "sec_proxy_creds" {
  path = "secret/keycloak/monitoring-proxy/credential"
  data_json = <<JSON
  {
      "client_id": "${ var.client_id }",
      "client_secret": "${ var.client_secret }",
      "encryption_key": "${ var.encryption_key }"
  }
  JSON
}

/*
resource "kubernetes_config_map" "cm_template" {
  metadata {
    name = "proxy-config-template"
    namespace = "linkerd"
  }
  data = {
    "config.hcl" = <<HCL
      vault {
        ssl {
          ca_cert = "/vault/tls/ca.crt"
        }
        retry {
          backoff = "1s"
        }
      }
      template {
        contents = <<EOH
          {{ '{{' }} with secret "secret/keycloak/monitoring-proxy/credential" {{ '}}' }}
          client_id = "{{ '{{' }} .Data.data.client_id {{ '}}' }}"
          client_secret = "{{ '{{' }} .Data.data.client_secret {{ '}}' }}"
          {{ '{{' }} end }}
          cookie_secret = "{{ '{{' }} .Data.data.encryption_key {{ '}}' }}"
          http_address = ":3000"
          upstreams = [ "http://linkerd-web.linkerd.svc.cluster.local:8084/" ]
          redirct_url = "https://monitoring.{{ domain }}"
          provider = "keycloak"
          login_url = "https://auth.{{ domain }}/realms/hausnet/protocol/openid-connect/auth"
          redeem_url ="https://auth.{{ domain }}/realms/hausnet/protocol/openid-connect/token"
          validate_url = "https://auth.{{ domain }}/realms/hausnet/protocol/openid-connect/userinfo"
        EOH
        destination = "/vault/secrets/oauth2-config.cfg"
        command = "/bin/sh -c \"kill -HUP $(pidof oauth2-proxy) || true\""
      }
    HCL
  }
}

resource "kubernetes_deployment" "dep_proxy" {
  metadata {
    name = "linkerd-web-proxy"
    namespace = "linkerd"
  }
  spec {
    selector {
      match_labels = {
        "app" = "linkerd-web-proxy"
      }
    }
    template {
      metadata {
        labels = {
          "app" = "linkerd-web-proxy"
        }
        annotations = {
          "vault.security.banzaicloud.io/vault-ct-configmap" = "proxy-config-template"
          "vault.security.banzaicloud.io/vault-addr" = "https://vault.vault-system:8200"
          "vault.security.banzaicloud.io/vault-tls-secret" = "vault-cert-tls"
          "vault.security.banzaicloud.io/vault-role" = "default"
        }
      }
      spec {
        container {
          name = "linkerd-web-proxy"
          image = "quay.io/oauth2-proxy/oauth2-proxy"
          port {
            container_port = 3000
          }
          args = [ "--config=/vault/secrets/oauth-config.cfg" ]
        }
      }
    }
  }
}

resource "kubernetes_service" "svc_proxy" {
  metadata {
    name = "linkerd-web-proxy"
    namespace = "linkerd"
  }
  spec {
    selector = {
      "app" = "linkerd-web-proxy"
    }
    port {
      port = 3000
      target_port = "3000"
    }
  }
}

resource "kubernetes_ingress" "ing_proxy" {
  metadata {
    name = "linkerd-web-proxy"
    namespace = "linkerd"
    annotations = {
      "kubernetes.io/ingress-class" = "traefik"
      "cert-manager.io/cluster-issuer" = "cluster-issuer"
      "traefik.ingress.kubernetes.io/redirect-entry-endpoint" = "https"
      "ingress.kubernetes.io/custom-request-headers" = "15d-dst-override:linkerd.web.linkerd.svc.cluster.local:8084"
    }
  }
  spec {
    rule {
      host = "monitoring.haus.net"
      http {
        path {
          path = "/"
          backend {
            service_name = "linkerd-web-proxy"
            service_port = "3000"
          }
        }
      }
    }
    tls {
      hosts = [ "monitoring.haus.net" ]
      secret_name = "proxy-tls-cert"
    }
  }
}
*/
