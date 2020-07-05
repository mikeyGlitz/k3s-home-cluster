### Keycloak ###

data "template_file" "temp_keycloak_vault" {
    template = file("./vault.yaml")
    vars = {
        namespace = "keycloak"
        account = "keycloak"
    }
}

data "template_file" "temp_owncloud_vault" {
    template = file("./vault.yaml")
    vars = {
        namespace = "owncloud"
        account = "owncloud"
    }
}

data "template_file" "temp_ldap_vault" {
    template = file("./vault.yaml")
    vars = {
        namespace = "ldap"
        account = "ldap"
    }
}

data "template_file" "temp_logging_vault" {
    template = file("./vault.yaml")
    vars = {
        namespace = "logging"
        account = "logging"
    }
}

data "template_file" "temp_linkerd_vault" {
    template = file("./vault.yaml")
    vars = {
        namespace = "linkerd"
        account = "linkerd"
    }
}

resource "kubectl_manifest" "mf_keycloak_vault" {
    yaml_body = data.template_file.temp_keycloak_vault.rendered

    depends_on = [
        kubernetes_cluster_role_binding.crb_vault,
        kubernetes_role_binding.rb_keycloak,
        kubernetes_role.role_keycloak,
        kubernetes_service_account.sa_keycloak
        ]
}

resource "kubectl_manifest" "mf_owncloud_vault" {
    yaml_body = data.template_file.temp_owncloud_vault.rendered

    depends_on = [
        kubernetes_cluster_role_binding.crb_vault,
        kubernetes_role_binding.rb_owncloud,
        kubernetes_role.role_owncloud,
        kubernetes_service_account.sa_owncloud
        ]
}
resource "kubectl_manifest" "mf_ldap_vault" {
    yaml_body = data.template_file.temp_ldap_vault.rendered

    depends_on = [
        kubernetes_cluster_role_binding.crb_vault,
        kubernetes_role_binding.rb_ldap,
        kubernetes_role.role_ldap,
        kubernetes_service_account.sa_ldap
        ]
}
resource "kubectl_manifest" "mf_logging_vault" {
    yaml_body = data.template_file.temp_logging_vault.rendered

    depends_on = [
        kubernetes_cluster_role_binding.crb_vault,
        kubernetes_role_binding.rb_logging,
        kubernetes_role.role_logging,
        kubernetes_service_account.sa_logging
        ]
}
resource "kubectl_manifest" "mf_linkerd_vault" {
    yaml_body = data.template_file.temp_linkerd_vault.rendered

    depends_on = [
        kubernetes_cluster_role_binding.crb_vault,
        kubernetes_role_binding.rb_linkerd,
        kubernetes_role.role_linkerd,
        kubernetes_service_account.sa_linkerd
        ]
}
