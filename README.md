# Kuberentes Terraform Scripts

This repository will use terraform to provision resources on a kuberentes cluster.

## Setting up Terraform

### Mac install

```bash
brew install terraform
```

### Windows Install

```powershell
choco install terraform
```

### Linux Install

```bash
wget https://releases.hashicorp.com/terraform/0.12.26/terraform_0.12.26_linux_amd64.zip
unzip terraform_0.12.26_linux_amd64.zipterraform_0.12.26_linux_amd64.zip
sudo mv terraform /usr/local/bin
```

### Kubectl Provider

This repository uses `kubectl` to provision some Kubernetes YAML manifests
The [Terraform Kubectl Provider](https://gavinbunney.github.io/terraform-provider-kubectl/docs/provider.html)
is a 3rd party Terraform provider which uses kubectl to provision YAML charts for Kubernetes

```bash
$ mkdir -p ~/.terraform.d/plugins && \
    curl -Ls https://api.github.com/repos/gavinbunney/terraform-provider-kubectl/releases/latest \
    | jq -r ".assets[] | select(.browser_download_url | contains(\"$(uname -s | tr A-Z a-z)\")) | select(.browser_download_url | contains(\"amd64\")) | .browser_download_url" \
    | xargs -n 1 curl -Lo ~/.terraform.d/plugins/terraform-provider-kubectl && \
    chmod +x ~/.terraform.d/plugins/terraform-provider-kubectl
```
