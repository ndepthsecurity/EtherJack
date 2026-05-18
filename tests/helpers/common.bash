REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Create a directory of stub executables that record their invocations and exit 0.
# A mock "nmap" is included that simulates an open port so connectivity checks pass.
create_mock_commands() {
    local mock_dir="$1"
    mkdir -p "$mock_dir"

    local commands="systemctl ifconfig route iptables init tshark tcpdump macchanger \
                    arping rfkill iw pkill dnsmasq hostapd sysctl ip hostname"
    for cmd in $commands; do
        cat > "$mock_dir/$cmd" << 'EOF'
#!/bin/bash
CMDNAME=$(basename "$0")
echo "MOCK:${CMDNAME} $*"
exit 0
EOF
        chmod +x "$mock_dir/$cmd"
    done

    # nmap: simulate an open port so the PortCheck loop exits on first attempt
    cat > "$mock_dir/nmap" << 'EOF'
#!/bin/bash
echo "Starting Nmap"
echo "PORT   STATE SERVICE"
echo "80/tcp open  http"
echo "Nmap done"
EOF
    chmod +x "$mock_dir/nmap"
}
