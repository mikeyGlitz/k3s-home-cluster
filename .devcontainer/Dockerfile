# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.140.1/containers/debian/.devcontainer/base.Dockerfile

# [Choice] Debian version: buster, stretch
ARG VARIANT="3.14"
FROM alpine/helm AS helm
FROM mcr.microsoft.com/vscode/devcontainers/base:0-alpine-${VARIANT}

COPY --from=helm --chmod=755 /usr/bin/helm /usr/local/bin

RUN apk update && apk add --no-cache \
    ca-certificates python3 py3-pip sshpass \
    gcc musl-dev python3-dev libffi-dev openssl-dev rust cargo gnupg \
    curl wget terraform \
    && update-ca-certificates

RUN pip3 install --upgrade pip setuptools

RUN pip3 install ansible openshift hvac ansible-lint

RUN wget https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl

RUN apk add --no-cache openssl

USER vscode

RUN  ansible-galaxy collection install kubernetes.core \
    && ansible-galaxy collection install community.general
