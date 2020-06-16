resource "kubernetes_service_account" "sa_keycloak" {
    metadata {
        name = "keycloak"
        namespace = "keycloak"
    }
    # automount_service_account_token = true
}

resource "kubernetes_role" "role_keycloak" {
    metadata {
        name = "vault-secrets"
        namespace = "keycloak"
    }
    rule {
        api_groups = [""]
        resources = [ "secrets" ]
        verbs = ["*"]
    }
}

resource "kubernetes_role_binding" "rb_keycloak" {
    metadata {
        name = "vault-secrets"
        namespace = "keycloak"
    }
    role_ref {
        api_group = "rbac.authorization.k8s.io"
        kind = "Role"
        name = "vault-secrets"
    }

    subject {
        kind = "ServiceAccount"
        name = "keycloak"
        namespace = "keycloak"
    }
}

resource "kubernetes_cluster_role_binding" "crb_keycloak" {
    metadata {
        name = "vault-auth-delegator"
    }
    role_ref {
        api_group = "rbac.authorization.k8s.io"
        kind = "ClusterRole"
        name = "system:auth-delegator"
    }

    subject {
        kind = "ServiceAccount"
        name = "keycloak"
        namespace = "keycloak"
    }
}
