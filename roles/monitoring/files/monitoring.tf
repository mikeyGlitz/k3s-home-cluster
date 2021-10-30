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
  path = "secret/monitoring-proxy/credential"
  data_json = <<JSON
  {
      "client_id": "${ var.client_id }",
      "client_secret": "${ var.client_secret }",
      "encryption_key": "${ var.encryption_key }"
  }
  JSON
}

resource "kubernetes_config_map" "cm_auth_proxy_config" {
  metadata {
    name = "oauth2-proxy-config"
    namespace = "linkerd-viz"
  }
  data = {
    "oauth2_proxy.cfg" = <<CFG
        provider = "keycloak"
        email_domains = ["*"]
        scope = "oidc"
        login_url = "https://auth.haus.net/auth/realms/hausnet/protocol/openid-connect/auth"
        redeem_url = "https://auth.haus.net/auth/realms/hausnet/protocol/openid-connect/token"
        validate_url = "https://auth.haus.net/auth/realms/hausnet/protocol/openid-connect/userinfo"
        keycloak_groups = ["/admin"]
        ssl_insecure_skip_verify = true
    CFG
  }
}

resource "helm_release" "rel_oauth2_proxy" {
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "oauth2-proxy"
  name       = "auth"
  namespace = "linkerd-viz"

  set {
    name  = "ingress.enabled"
    value = "true"
  }
  set {
    name  = "ingress.pathType"
    value = "Prefix"
  }
  set {
    name  = "ingress.hostname"
    value = "monitoring.haus.net"
  }

  set {
    name  = "ingress.path"
    value = "/oauth2"
  }

  set {
    name  = "ingress.annotations.kubernetes\\.io/class\\.name"
    value = "nginx"
  }
  set {
    name  = "ingress.annotations.cert-manager\\.io/cluster-issuer"
    value = "cluster-issuer"
  }
  set {
    name  = "ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/ssl-redirect"
    value = "'true'"
  }
  set {
    name  = "ingress.tls"
    value = "true"
  }

  set {
    name  = "configuration.clientID"
    value = "vault:secret/data/monitoring-proxy/credential#client_id"
  }
  set {
    name  = "configuration.clientSecret"
    value = "vault:secret/data/monitoring-proxy/credential#client_secret"
  }
  set {
    name  = "configuration.cookieSecret"
    value = "vault:secret/data/monitoring-proxy/credential#encryption_key"
  }

  set {
    name  = "configuration.existingConfigmap"
    value = "oauth2-proxy-config"
  }

  set {
    name  = "podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-addr"
    value = "https://vault.vault-system:8200"
  }

  set {
    name  = "podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-role"
    value = "default"
  }
  set {
    name  = "podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-tls-secret"
    value = "vault-cert-tls"
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }
}