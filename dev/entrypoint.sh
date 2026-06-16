#!/bin/bash

# ---------------------------------------------------------------------------
# EtherJack dev environment entrypoint
#
# Sets up a virtual eth0 using a veth pair and a dummy wlan0, then drops
# to an interactive bash shell so you can run / edit EtherJack scripts
# without real Pi hardware.
#
# Known limitations (QEMU user-static on x86):
#   tshark/tcpdump — AF_PACKET socket operations are not fully emulated;
#       live packet capture fails. netfinder.sh will not collect IPs.
#       Use the BATS test suite for unit testing capture logic.
#   hostapd  — needs a real wireless driver; WIFI mode starts but
#       hostapd will fail to bind. The rest of wifi.sh runs fine.
#   init 0   — intercepted so the container isn't killed on an invalid
#       EJMODE value.
# ---------------------------------------------------------------------------

echo ""
echo "  ███████╗████████╗██╗  ██╗███████╗██████╗      ██╗ █████╗  ██████╗██╗  ██╗"
echo "  ██╔════╝╚══██╔══╝██║  ██║██╔════╝██╔══██╗     ██║██╔══██╗██╔════╝██║ ██╔╝"
echo "  █████╗     ██║   ███████║█████╗  ██████╔╝     ██║███████║██║     █████╔╝ "
echo "  ██╔══╝     ██║   ██╔══██║██╔══╝  ██╔══██╗██   ██║██╔══██║██║     ██╔═██╗ "
echo "  ███████╗   ██║   ██║  ██║███████╗██║  ██║╚█████╔╝██║  ██║╚██████╗██║  ██╗"
echo "  ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝"
echo ""
echo "  ARM dev environment — $(uname -m)"
echo ""

# ---------------------------------------------------------------------------
# Intercept init so invalid/empty EJMODE doesn't kill the container
# ---------------------------------------------------------------------------
mkdir -p /dev-bin
cat >/dev-bin/init <<'EOF'
#!/bin/bash
echo "[dev] init $* called — ignoring shutdown in dev environment"
EOF
chmod +x /dev-bin/init
export PATH="/dev-bin:$PATH"

# ---------------------------------------------------------------------------
# Virtual eth0 via veth pair
#   eth0      — EtherJack's interface (what the scripts see)
#   eth0-peer — available if you want to inject traffic manually
# ---------------------------------------------------------------------------
ip link add eth0 type veth peer name eth0-peer 2>/dev/null || true
ip link set eth0 up 2>/dev/null || true
ip link set eth0-peer up 2>/dev/null || true

# ---------------------------------------------------------------------------
# Dummy wlan0 (enough for wifi.sh to configure IP / iptables rules;
# hostapd will fail to bind — that's a known dev limitation)
# ---------------------------------------------------------------------------
ip link add wlan0 type dummy 2>/dev/null || true
ip link set wlan0 up 2>/dev/null || true

echo "  ##############################################################"
echo "  #                   KNOWN DEV LIMITATIONS                   #"
echo "  ##############################################################"
echo "  tshark/tcpdump  — live capture fails (QEMU AF_PACKET limitation)."
echo "                    On real hardware eth0 would have live LAN traffic."
echo "  hostapd         — needs a real wireless driver; won't bind to wlan0."
echo "  ##############################################################"
echo ""
echo "  ##############################################################"
echo "  #                   INTERFACES                              #"
echo "  ##############################################################"
ip -brief link 2>/dev/null || true
echo ""
echo "  ##############################################################"
echo "  #                   ENVIRONMENT INFO                        #"
echo "  ##############################################################"
echo "  Repo mounted at : /usr/local/EtherJack"
echo "  Current EJMODE  : $(grep '^EJMODE=' /usr/local/EtherJack/EtherJack.conf 2>/dev/null || echo 'not set')"
echo ""
echo "  To run EtherJack (on real hardware this starts automatically on boot):"
echo "    cd /usr/local/EtherJack && bash EtherJack.sh"
echo ""

# Pass through any arguments (e.g. bash -c '...' for scripted use);
# default to an interactive shell (not --login; avoids Kali profile scripts
# that can hang or suppress the prompt in the ARM QEMU environment)
if [ $# -gt 0 ]; then
    exec "$@"
else
    exec bash -i
fi
