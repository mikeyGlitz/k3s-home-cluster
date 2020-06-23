# resource "kubectl_manifest" "mf_ldap_cert" {
#   yaml_body = <<YAML
#     apiVersion: cert-manager.io/v1alpha2
#     kind: Certificate
#     metadata:
#         name: ldap-app-cert
#         namespace: ldap
#     spec:
#         secretName: ldap-openldap-app-tls
#         dnsNames:
#         - ldap-openldap
#         - ldap-openldap.ldap
#         - ldap-openldap.ldap.svc
#         - ldap-openldap.ldap.svc.cluster
#         - ldap-openldap.ldap.svc.cluster.local
#         ipAddresses:
#         - 192.168.0.120
#         - 127.0.0.1
#         issuerRef:
#             name: cluster-issuer
#             kind: ClusterIssuer
#   YAML
# }

resource "kubernetes_secret" "sec_ldap_pass" {
  metadata {
    name = "ldap-passwords"
    namespace = "ldap"
    annotations = {
      "vault.security.banzaicloud.io/vault-skip-verify" = "true"
      "vault.security.banzaicloud.io/vault-addr" = "https://vault.ldap:8200"
      "vault.security.banzaicloud.io/vault-role" = "default"
      "vault.security.banzaicloud.io/vault-path" = "kubernetes"
    }
  }
  data = {
    "LDAP_CONFIG_PASSWORD" = "vault:secret/data/ldap/config/credentials#config_password"
    "LDAP_ADMIN_PASSWORD" = "vault:secret/data/ldap/admin/credentials#admin_password"
  }
}

resource "helm_release" "rel_ldap" {
  repository = "https://kubernetes-charts.storage.googleapis.com"
  chart = "openldap"
  name = "ldap"
  namespace = "ldap"
  # set {
  #   name = "tls.enabled"
  #   value = "true"
  # }
  # set {
  #   name = "tls.secret"
  #   value = "ldap-openldap-app-tls"
  # }
  # set {
  #   name = "tls.CA.enabled"
  #   value = "true"
  # }
  # set {
  #   name = "tls.CA.secret"
  #   value = "ldap-openldap-app-tls"
  # }
  set {
    name = "env.LDAP_ORGANISATION"
    value = "Home Network"
  }
  set {
    name = "env.LDAP_DOMAIN"
    value = "haus.net"
  }
  set {
    name = "existingSecret"
    value = "ldap-passwords"
  }
}

resource "kubectl_manifest" "mf_ldap_admin_cert" {
  yaml_body = <<YAML
    apiVersion: cert-manager.io/v1alpha2
    kind: Certificate
    metadata:
        name: ldap-admin-cert
        namespace: ldap
    spec:
        secretName: ldap-openldap-admin-tls
        dnsNames:
        - ldap-phpldapadmin
        - ldap-phpldapadmin.ldap
        - ldap-phpldapadmin.ldap.svc
        - ldap-phpldapadmin.ldap.svc.cluster
        - ldap-phpldapadmin.ldap.svc.cluster.local
        ipAddresses:
        - 192.168.0.120
        - 127.0.0.1
        issuerRef:
            name: cluster-issuer
            kind: ClusterIssuer
  YAML
}

resource "helm_release" "rel_ldap_admin" {
  repository = "https://cetic.github.io/helm-charts"
  chart = "phpldapadmin"
  name = "admin"
  namespace = "ldap"

  values = [
      <<YAML
        ingress:
          hosts:
          - ldap.haus.net
          tls:
          - secretName: ldap-openldap-admin-tls
            hosts:
            - ldap.haus.net
        env:
          PHPLDAPADMIN_HTTPS: "false"
          PHPLDAPADMIN_TRUST_PROXY_SSL: "true"
          PHPLDAPADMIN_LDAP_CLIENT_TLS_REQCERT: "allow"
          PHPLDAPADMIN_LDAP_HOSTS: "#PYTHON2BASH:[{'ldap-openldap.ldap.svc.cluster.local': [{'server': [{'port': '389'}]},{'login': [{ 'bind_id': 'cn=admin,dc=haus,dc=net'}]}]}]"
          # PHPLDAPADMIN_LDAP_HOSTS: "#PYTHON2BASH:[{'ldap-openldap.ldap.svc.cluster.local': [{'server': [{'tls': 'true'},{'port': '389'}]},{'login': [{ 'bind_id': 'cn=admin,dc=haus=,dc=net'}]}]}]"
      YAML
  ]

  set {
    name = "ingress.enabled"
    value = "true"
  }
  set {
    name = "ingress.annotations.kubernetes\\.io/ingress\\.class"
    value = "traefik"
  }
  set {
    name = "ingress.annotations.cert-manager\\.io/cluster-issuer"
    value = "cluster-issuer"
  }
  set {
    name = "ingress.annotations.traefik\\.ingress\\.kubernetes\\.io/redirect-entry-point"
    value = "https"
  }
  set {
    name = "service.type"
    value = "ClusterIP"
  }
}
