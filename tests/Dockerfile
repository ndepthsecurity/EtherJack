FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        bash \
        shellcheck \
        yamllint \
        git \
        ca-certificates \
        curl \
    && git clone --depth 1 https://github.com/bats-core/bats-core.git /tmp/bats-core \
    && /tmp/bats-core/install.sh /usr/local \
    && rm -rf /tmp/bats-core \
    && curl -sSL https://github.com/mvdan/sh/releases/download/v3.13.0/shfmt_v3.13.0_linux_amd64 \
        -o /usr/local/bin/shfmt \
    && chmod +x /usr/local/bin/shfmt \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /etherjack
