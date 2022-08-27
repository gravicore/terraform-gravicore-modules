# [Choice] Alpine version: 3.16, 3.15, 3.14, 3.13
ARG VARIANT=3.16
FROM mcr.microsoft.com/vscode/devcontainers/base:0-alpine-${VARIANT}

# ** [Optional] Uncomment this section to install additional packages. **
RUN apk -U upgrade && apk add --no-cache \
    aws-cli \
    bash \
    ca-certificates \
    curl \
    git \
    jq \
    openssh \
    openssh-keygen \
    tzdata