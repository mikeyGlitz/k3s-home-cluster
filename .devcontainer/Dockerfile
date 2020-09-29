# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.140.1/containers/debian/.devcontainer/base.Dockerfile

# [Choice] Debian version: buster, stretch
ARG VARIANT="buster"
FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}

# ** [Optional] Uncomment this section to install additional packages. **
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends python3-pip \
    python3-setuptools \
    apt-transport-https \
    gnupg2 \
    sshpass \
    curl && \
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - && \
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list && \
    sudo apt-get update \
    && apt-get -y install --no-install-recommends kubectl \
    && pip3 install ansible openshift hvac \
    && ansible-galaxy collection install community.kubernetes \
    && ansible-galaxy collection install community.general \
    && curl -fsSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
