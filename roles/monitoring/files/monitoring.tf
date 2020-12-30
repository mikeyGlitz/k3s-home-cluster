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

resource "helm_release" "rel_oauth2_proxy" {
  repository = "https://k8s-at-home.com/charts/"
  chart = "oauth2-proxy"
  name = "auth"
  namespace = "linkerd"

  values = [ 
    <<YAML
    extraArgs:
      provider: keycloak
      email-domain: "*"
      scope: "openid profile email"
      login-url: https://auth.haus.net/auth/realms/hausnet/protocol/openid-connect/auth
      redeem-url: https://auth.haus.net/auth/realms/hausnet/protocol/openid-connect/token
      validate-url: https://auth.haus.net/auth/realms/hausnet/protocol/openid-connect/userinfo
      keycloak-group: /admin
      ssl-insecure-skip-verify: true
    ingress:
      enabled: true
      hosts:
        - monitoring.haus.net
      path: /oauth2
      annotations:
        kubernetes.io/ingress.class: nginx
        cert-manager.io/cluster-issuer: cluster-issuer
        nginx.ingress.kubernetes.io/ssl-redirect: 'true'
      tls:
        - secretName: oauth-proxy-tls
          hosts:
            - monitoring.haus.net
    extraEnv:
      - name: OAUTH2_PROXY_CLIENT_ID
        value: vault:secret/data/keycloak/monitoring-proxy/credential#client_id
      - name: OAUTH2_PROXY_CLIENT_SECRET
        value: vault:secret/data/keycloak/monitoring-proxy/credential#client_secret
      - name: OAUTH2_PROXY_COOKIE_SECRET
        value: vault:secret/data/keycloak/monitoring-proxy/credential#encryption_key
    YAML
   ]

  set {
    name = "proxyVarsAsSecrets"
    value = "false"
  }

  set {
    name = "podAnnotations.linkerd\\.io/inject"
    value = "enabled"
  }

  set {
    name = "podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-addr"
    value = "https://vault.vault-system:8200"
  }

  set {
    name = "podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-role"
    value = "default"
  }
  set {
    name = "podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-tls-secret"
    value = "vault-cert-tls"
  }

  set {
    name = "serviceAccount.enabled"
    value = "false"
  }
}