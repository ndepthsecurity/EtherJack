FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        bash \
        shellcheck \
        git \
        ca-certificates \
    && git clone --depth 1 https://github.com/bats-core/bats-core.git /tmp/bats-core \
    && /tmp/bats-core/install.sh /usr/local \
    && rm -rf /tmp/bats-core \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /etherjack
