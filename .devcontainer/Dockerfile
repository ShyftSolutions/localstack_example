# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.209.6/containers/ubuntu/.devcontainer/base.Dockerfile

# [Choice] Ubuntu version (use hirsuite or bionic on local arm64/Apple Silicon): hirsute, focal, bionic
ARG VARIANT="hirsute"
FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}

COPY terraform-debian.sh /tmp/library-scripts/

RUN apt-get update && bash /tmp/library-scripts/terraform-debian.sh \
    && apt-get -y update \
    && apt-get -y install python3-pip \
    && pip3 install awscli-local[ver1]
