### Keycloak ###

data "template_file" "temp_keycloak_vault" {
    template = file("./vault.yaml")
    vars = {
        namespace = "keycloak"
        account = "keycloak"
    }
}

resource "kubectl_manifest" "mf_keycloak_vault" {
    yaml_body = data.template_file.temp_keycloak_vault.rendered

    depends_on = [
        kubernetes_cluster_role_binding.crb_keycloak,
        kubernetes_role_binding.rb_keycloak,
        kubernetes_role.role_keycloak,
        kubernetes_service_account.sa_keycloak
        ]
}
