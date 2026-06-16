FROM --platform=linux/arm/v7 kalilinux/kali-rolling

ARG DEBIAN_FRONTEND=noninteractive

# All tools EtherJack scripts call at runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
        bash \
        tshark \
        tcpdump \
        nmap \
        macchanger \
        iproute2 \
        net-tools \
        iptables \
        iputils-arping \
        hostapd \
        dnsmasq \
        iw \
        rfkill \
        openssh-server \
        procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /usr/local/EtherJack
ENTRYPOINT ["/entrypoint.sh"]
