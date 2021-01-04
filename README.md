# Kuberentes Cluster Provisioner

This Project contains a configuration-as-code set up which
utilizes Ansible to provision a Kubernetes cluster using
[k3s](https://rancher.com/docs/k3s/latest/en/).

## Setting up Ansible

Make sure that python3 and pip are installed.

```bash
# Debian/Ubuntu
sudo apt-get update && sudo apt-get install -y python3 python3-pip
# Mac
brew install python3
```

Install Ansible using pip

```bash
pip3 install ansible
```

> ℹ If you're using [Visual Studio Remote Containers](https://code.visualstudio.com/docs/remote/containers)
> for VS Code, installing the tools will have already been completed during the container
> Installation procedures (see the files in `.devcontainer`)

## Running the Ansible Scripts

This script is designed to be run in two steps:

```bash
# First Run
ansible-playbook --ask-pass playbook.yml --skip-tags=media
# Last Run
ansible-playbook --ask-pass playbook.yml --tags=media --extra-vars="plex_token=<plex_claim_token>"
```

You can obtain a plex token by visiting https://plex.tv/claim
Plex tokens are only valid for 4 minutes. This playbook takes longer than 4 minutes to run
which is why the media role needs to be executed separately.

### Variables

A set of variables are defined within this playbook.
The values can be overridden using the Ansible [--extra-vars](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#key-value-format)
argument.

The full variables list is detailed below:

| Variable            | Default   | Description                           |
|---------------------|-----------|---------------------------------------|
| terraform_version   | 0.13.1    | Version of Terraform to install       |
| kubectl_version     | 1.6.2     | Version of Terraform kubectl provider |
| domain              | haus.net  | Domain name                           |
| ip_addresses        | []        | List of IP addresses for k8s cluster  |
| keycloak_user       | manager   | Default Admin user for Keycloak       |
| keycloak_password   | p@$$w0rd! | Default Admin password for Keycloak   |
| ldap_password       | p@$$w0rd! | Default password for LDAP admin acct  |
| plex_token          | ""        | Plex claim token for new plex server  |
| files_user          | manager   | Default Admin user for Owncloud       |
| files_password      | p@$$w0rd! | Default Admin password for Owncloud   |

# References

- [k3sup](https://github.com/alexellis/k3sup)
- [Ingress-Nginx](https://kubernetes.github.io/ingress-nginx/)
- [Injecting Vault secrets](https://banzaicloud.com/blog/inject-secrets-into-pods-vault-revisited/)
- [Logging Operator](https://banzaicloud.com/docs/one-eye/logging-operator/quickstarts/loki-nginx/)
- [Customizing Linkerd Installation](https://linkerd.io/2/tasks/customize-install/)
- [Exposing Linkerd Dashboard](https://linkerd.io/2/tasks/exposing-dashboard/)
- [Linkerd Helm Charts](https://github.com/linkerd/linkerd2/tree/main/charts/) _Look for add-ons_
- [Exposing TCP Services](https://kubernetes.github.io/ingress-nginx/user-guide/exposing-tcp-udp-services/)