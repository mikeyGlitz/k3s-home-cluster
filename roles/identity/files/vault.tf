variable "keycloak_database_password" {
    type = string
    description = "Password for the keycloak database"
}

variable "keycloak_app_password" {
    type = string
    description = "Password for the keycloak application"
}

variable "keycloak_app_user" {
    type = string
    description = "Username of the keycloak user"
    default = "manager"
}

variable "keycloak_database_user" {
    type = string
    description = "Keycloak database user"
    default = "keycloak"
}

resource "vault_generic_secret" "sec_keycloak_db" {
    path = "secret/keycloak/database/credential"
    data_json = <<JSON
        {
            "database_user": "${ var.keycloak_database_user }",
            "database_password": "${ var.keycloak_database_password }"
        }
    JSON
}

resource "vault_generic_secret" "sec_keycloak_app" {
    path = "secret/keycloak/application/credential"
    data_json = <<JSON
        {
            "app_user": "${ var.keycloak_app_user }",
            "app_password": "${ var.keycloak_app_password }"
        }
    JSON
}