ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: cluster-issuer
    nginx.ingress.kubernetes.io/ssl-redirect: 'true'
    nginx.ingress.kubernetes.io/proxy-body-size: 2g
  tls:
    - hosts:
      - files.haus.net
      secretName: nextcloud-app-tls
nextcloud:
  host: files.haus.net
  username: vault:secret/data/nextcloud/app/credentials#app_user
  password: vault:secret/data/nextcloud/app/credentials#app_password
  configs:
    oidc.config.php: |
      <?php
        # Configuration obtained from https://blog.lachlanlife.net/nextcloud-part-3-single-sign-on-with-keycloak/
        $CONFIG = array(
          'overwrite_cli_url' => 'https://files.haus.net',
          'allow_user_to_change_display_name' => false,
          'lost_password_link' => 'disabled',
          'oidc_login_disable_registration' => false,
          'oidc_login_provider_url' => 'https://auth.haus.net/auth/realms/hausnet',
          'oidc_login_client_id' => 'files-portal',
          'oidc_login_client_secret' => '${client_secret}',
          'oidc_login_auto_redirect' => false,
          'oidc_login_auto_redir_fallback' => true,
          'odic_login_logout_url' => 'https://auth.haus.net/auth/realms/hausnet/protocol/openid-connect/logout?redirect_uri=https%3A%2F%files.haus.net%2F',
          'oidc_login_button_text' => 'Home Network SSO',
          'oidc_login_scope' => 'openid profile',
          'oidc_login_default_quota' => '100000000000',
          'oidc_login_attributes' => array(
            'id' => 'preferred_username',
            'mail' => 'email',
            'name' => 'name',
            'groups' => 'groups',
            'quota' => 'ownCloudQuota'
          ),
          'mode' => 'userid',
          'oidc_create_groups' => true,
          'overwriteprotocol' => 'https',
          'oidc_login_tls_verify' => false,
        );
persistence:
  enabled: yes
  storageClass: nfs-client
  size: 2.5Ti
  accessMode: ReadWriteMany
podAnnotations:
  vault.security.banzaicloud.io/vault-addr: https://vault.vault-system:8200
  vault.security.banzaicloud.io/vault-tls-secret: vault-cert-tls
  vault.security.banzaicloud.io/vault-role: files
internalDatabase:
  enabled: no
externalDatabase:
  type: postgresql
  host: cloudfiles-postgresql
  database: nextcloud
postgresql:
  enabled: yes
  postgresqlDatabase: nextcloud
  postgresqlUsername: vault:secret/data/nextcloud/db/credentials#db_user
  postgresqlPassword: vault:secret/data/nextcloud/db/credentials#db_password
  serviceAccount:
    enabled: yes
    name: nextcloud
    autoMount: true
  primary:
    persistence:
      storageClass: nfs-client
    podAnnotations:
      vault.security.banzaicloud.io/vault-addr: https://vault.vault-system:8200
      vault.security.banzaicloud.io/vault-tls-secret: vault-cert-tls
      vault.security.banzaicloud.io/vault-role: files
redis:
  enabled: yes
  usePassword: yes
  password: ${redisPassword}
rbac:
  enabled: yes
  serviceaccount:
    create: yes
    name: nextcloud
livenessProbe:
  enabled: yes
  initialDelaySeconds: 600
readinessProbe:
  enabled: no
