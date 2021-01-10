variable "client_secret" {
    type = string
    description = "Openfaas client secret"
}

variable "client_id" {
    type = string
    description = "Openfaas client id"
}


variable "encryption_key" {
    type = string
    description = "Cookie encryption key"
}

resource "vault_generic_secret" "sec_proxy_creds" {
  path = "secret/openfaas/credential"
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
  namespace = "openfaas"

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
        - functions.haus.net
      path: /oauth2
      annotations:
        kubernetes.io/ingress.class: nginx
        cert-manager.io/cluster-issuer: cluster-issuer
        nginx.ingress.kubernetes.io/ssl-redirect: 'true'
      tls:
        - secretName: oauth-proxy-tls
          hosts:
            - functions.haus.net
    extraEnv:
      - name: OAUTH2_PROXY_CLIENT_ID
        value: vault:secret/data/openfaas/credential#client_id
      - name: OAUTH2_PROXY_CLIENT_SECRET
        value: vault:secret/data/openfaas/credential#client_secret
      - name: OAUTH2_PROXY_COOKIE_SECRET
        value: vault:secret/data/openfaas/credential#encryption_key
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

resource "helm_release" "rel_openfaas" {
  repository = "https://openfaas.github.io/faas-netes/"
  name = "openfaas"
  chart="openfaas"
  namespace = "openfaas"

  set {
      name = "functionNamespace"
      value = "openfaas-fn"
  }

  set {
      name = "generateBasicAuth"
      value = "false"
  }

  set {
      name = "basic_auth"
      value = "false"
  }

  set {
      name = "serviceType"
      value = "ClusterIP"
  }
}