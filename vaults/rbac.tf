### Keycloak RBAC ###
resource "kubernetes_service_account" "sa_keycloak" {
    metadata {
        name = "keycloak"
        namespace = "keycloak"
    }
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

### OwnCloud RBAC ###
resource "kubernetes_service_account" "sa_owncloud" {
    metadata {
        name = "owncloud"
        namespace = "owncloud"
    }
}

resource "kubernetes_role" "role_owncloud" {
    metadata {
        name = "vault-secrets"
        namespace = "owncloud"
    }
    rule {
        api_groups = [""]
        resources = [ "secrets" ]
        verbs = ["*"]
    }
}

resource "kubernetes_role_binding" "rb_owncloud" {
    metadata {
        name = "vault-secrets"
        namespace = "owncloud"
    }
    role_ref {
        api_group = "rbac.authorization.k8s.io"
        kind = "Role"
        name = "vault-secrets"
    }

    subject {
        kind = "ServiceAccount"
        name = "owncloud"
        namespace = "owncloud"
    }
}

### LDAP RBAC ###
resource "kubernetes_service_account" "sa_ldap" {
    metadata {
        name = "ldap"
        namespace = "ldap"
    }
}

resource "kubernetes_role" "role_ldap" {
    metadata {
        name = "vault-secrets"
        namespace = "ldap"
    }
    rule {
        api_groups = [""]
        resources = [ "secrets" ]
        verbs = ["*"]
    }
}

resource "kubernetes_role_binding" "rb_ldap" {
    metadata {
        name = "vault-secrets"
        namespace = "ldap"
    }
    role_ref {
        api_group = "rbac.authorization.k8s.io"
        kind = "Role"
        name = "vault-secrets"
    }

    subject {
        kind = "ServiceAccount"
        name = "ldap"
        namespace = "ldap"
    }
}
### Logging RBAC ###
resource "kubernetes_service_account" "sa_logging" {
    metadata {
        name = "logging"
        namespace = "logging"
    }
}

resource "kubernetes_role" "role_logging" {
    metadata {
        name = "vault-secrets"
        namespace = "logging"
    }
    rule {
        api_groups = [""]
        resources = [ "secrets" ]
        verbs = ["*"]
    }
}

resource "kubernetes_role_binding" "rb_logging" {
    metadata {
        name = "vault-secrets"
        namespace = "logging"
    }
    role_ref {
        api_group = "rbac.authorization.k8s.io"
        kind = "Role"
        name = "vault-secrets"
    }

    subject {
        kind = "ServiceAccount"
        name = "logging"
        namespace = "logging"
    }
}

### linkerd RBAC ###
resource "kubernetes_service_account" "sa_linkerd" {
    metadata {
        name = "linkerd"
        namespace = "linkerd"
    }
}

resource "kubernetes_role" "role_linkerd" {
    metadata {
        name = "vault-secrets"
        namespace = "linkerd"
    }
    rule {
        api_groups = [""]
        resources = [ "secrets" ]
        verbs = ["*"]
    }
}

resource "kubernetes_role_binding" "rb_linkerd" {
    metadata {
        name = "vault-secrets"
        namespace = "linkerd"
    }
    role_ref {
        api_group = "rbac.authorization.k8s.io"
        kind = "Role"
        name = "vault-secrets"
    }

    subject {
        kind = "ServiceAccount"
        name = "linkerd"
        namespace = "linkerd"
    }
}

### ClusterRoleBinding ###
resource "kubernetes_cluster_role_binding" "crb_vault" {
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
    subject {
        kind = "ServiceAccount"
        name = "owncloud"
        namespace = "owncloud"
    }
    subject {
        kind = "ServiceAccount"
        name = "ldap"
        namespace = "ldap"
    }
    subject {
        kind = "ServiceAccount"
        name = "logging"
        namespace = "logging"
    }
    subject {
        kind = "ServiceAccount"
        name = "linkerd"
        namespace = "linkerd"
    }
}
