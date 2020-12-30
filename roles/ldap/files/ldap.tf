variable "ldap_password" {
    type = string
    description = "(optional) describe your variable"
}

resource "kubernetes_namespace" "ns_ldap" {
  metadata {
    name = "ldap"
    annotations = {
        "linkerd.io/inject" = "enabled"
    }
  }
}

resource "vault_generic_secret" "sec_ldap" {
  path = "secret/ldap/credential"
  data_json = <<JSON
  {
    "ldap_password": "${var.ldap_password}"
  }
  JSON
}

resource "helm_release" "name" {
  repository = "https://geek-cookbook.github.io/charts/"
  chart = "openldap"
  namespace = "ldap"
  name = "directory"

  set {
    name = "env.LDAP_ORGANISATION"
    value = "hausnet"
  }

  set {
      name = "env.LDAP_DOMAIN"
      value = "haus.net"
  }

  set {
    name = "adminPassword"
    value = "vault:secret/data/ldap/credential#ldap_password"
  }
  set {
    name = "persistence.enabled"
    value = "true"
  }
  set {
    name = "persistence.storageClass"
    value = "nfs-client"
  }

  set {
    name = "podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-addr"
    value = "https://vault.vault-system:8200"
  }
  set {
    name = "podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-tls-secret"
    value = "vault-cert-tls"
  }
  set {
    name = "podAnnotations.vault\\.security\\.banzaicloud\\.io/vault-role"
    value = "default"
  }
}

resource "helm_release" "rel_ldapadmin" {
  repository = "https://cetic.github.io/helm-charts"
  name = "phpldapadmin"
  chart = "phpldapadmin"
  namespace = "ldap"

  values = [ 
    <<YAML
    ingress:
      enabled: 'true'
      annotations:
        kubernetes.io/ingress-class: "nginx"
        cert-manager.io/cluster-issuer: "cluster-issuer"
        nginx.ingress.kubernetes.io/ssl-redirect: "true"
      hosts:
        - ldap.haus.net
      tls:
        - secretName: ldap-tls-cert
          hosts:
            - ldap.haus.net
    YAML
   ]

  set {
    name = "service.type"
    value = "ClusterIP"
  }

  set {
    name = "env.PHPLDAPADMIN_LDAP_HOSTS"
    value = "directory-openldap"
  }
}
