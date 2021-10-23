variable "client_secret" {
  type        = string
  description = "Openfaas client secret"
}

variable "client_id" {
  type        = string
  description = "Openfaas client id"
}


variable "encryption_key" {
  type        = string
  description = "Cookie encryption key"
}

variable "openfaas_user" {
  type = string
  description = "Openfaas console username"
  default = "openfaas"
}

variable "openfaas_password" {
  type = string
  description = "OpenFaas Basic Auth password"
}

resource "vault_generic_secret" "sec_proxy_creds" {
  path      = "secret/openfaas/credential"
  data_json = <<JSON
  {
      "client_id": "${var.client_id}",
      "client_secret": "${var.client_secret}",
      "encryption_key": "${var.encryption_key}",
      "openfaas_password": "${var.openfaas_password}"
  }
  JSON
}

resource "kubernetes_config_map" "cm_auth_proxy_config" {
  metadata {
    name = "oauth2-proxy-config"
    namespace = "openfaas"
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
        skip_auth_routes = [
          "^/function",
          "^/system"
        ]
    CFG
  }
}

resource "helm_release" "rel_oauth2_proxy" {
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "oauth2-proxy"
  name       = "auth"
  namespace  = "openfaas"

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
    value = "functions.haus.net"
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
    value = "vault:secret/data/openfaas/credential#client_id"
  }
  set {
    name  = "configuration.clientSecret"
    value = "vault:secret/data/openfaas/credential#client_secret"
  }
  set {
    name  = "configuration.cookieSecret"
    value = "vault:secret/data/openfaas/credential#encryption_key"
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

resource "kubernetes_secret" "sec_basic_auth" {
  metadata {
    name = "basic-auth"
    namespace = "openfaas"
    annotations = {
      "vault.security.banzaicloud.io/vault-addr" = "https://vault.vault-system:8200"
      "vault.security.banzaicloud.io/vault-role" = "default"
      "vault.security.banzaicloud.io/vault-skip-verify" = "true"
      "vault.security.banzaicloud.io/vault-path" = "kubernetes"
    }
  }
  data = {
    "basic-auth-user" = var.openfaas_user
    "basic-auth-password" = "vault:secret/data/openfaas/credential#openfaas_password"
  }
}

resource "helm_release" "rel_openfaas" {
  repository = "https://openfaas.github.io/faas-netes/"
  name       = "openfaas"
  chart      = "openfaas"
  namespace  = "openfaas"

  set {
    name  = "functionNamespace"
    value = "openfaas-fn"
  }

  set {
    name  = "generateBasicAuth"
    value = "false"
  }

  set {
    name  = "basic_auth"
    value = "true"
  }

  set {
    name  = "serviceType"
    value = "ClusterIP"
  }

  set {
    name  = "ingressOperator.create"
    value = "true"
  }
}

resource "helm_release" "rel_cron_connector" {
  name = "cron"
  namespace = "openfaas"
  chart = "cron-connector"
  repository = "https://openfaas.github.io/faas-netes/"
}

resource "helm_release" "rel_openfaas_loki" {
  name       = "loki"
  namespace  = "openfaas"
  repository = "https://lucasroesler.com/openfaas-loki"
  chart      = "openfaas-loki"
  set {
    name  = "lokiURL"
    value = "http://loki.logging:3100"
  }
  set {
    name  = "logLevel"
    value = "DEBUG"
  }
}