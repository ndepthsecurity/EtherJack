#!/usr/bin/env bats
#
# Tests for preset/preset.sh CONFIG branching.
#
# preset.sh uses two relative sources:
#   source ../../EtherJack.conf   (resolved from CWD = $EJPATH/preset/engagement/)
#   source ../preset.conf         (resolved from CWD = $EJPATH/preset/engagement/)
#
# We replicate that directory layout in BATS_TEST_TMPDIR, stub all
# system commands, and run preset.sh from the engagement directory.

load 'helpers/common'

ENGAGEMENT="eng001"

setup() {
    export EJPATH="$BATS_TEST_TMPDIR/ej"
    mkdir -p "$EJPATH/preset/$ENGAGEMENT" "$EJPATH/bin"

    # Mock system commands (includes init, nmap open-port stub, etc.)
    export MOCK_BIN="$BATS_TEST_TMPDIR/bin"
    create_mock_commands "$MOCK_BIN"

    # Override init to record the shutdown call without touching the system
    cat > "$MOCK_BIN/init" << 'EOF'
#!/bin/bash
echo "SHUTDOWN: init $*"
exit 0
EOF
    chmod +x "$MOCK_BIN/init"
    export PATH="$MOCK_BIN:$PATH"

    # Mock payload (CALLHOME target)
    cat > "$EJPATH/bin/payload" << 'EOF'
#!/bin/bash
echo "payload executed"
EOF
    chmod +x "$EJPATH/bin/payload"

    # EtherJack.conf — sourced via ../../EtherJack.conf from the engagement dir
    cat > "$EJPATH/EtherJack.conf" << EOF
EJMODE=PRESET
EJPATH=$EJPATH
ENGAGEMENT=$ENGAGEMENT
EJLOG=ej.log
EJEXE=payload
CALLHOME=$EJPATH/bin/payload
PKTS=5
TESTIP=93.184.216.34
TESTPORT=80
EOF
}

# Helper: write preset.conf and run preset.sh from the engagement directory.
# preset.sh is at $EJPATH/preset/preset.sh; from engagement/ it's ../preset.sh.
run_preset() {
    local config="$1"
    cat > "$EJPATH/preset/preset.conf" << EOF
CONFIG=$config
IPADDR=192.168.1.100
NETMASK=255.255.255.0
GATEWAY=192.168.1.1
NAMESERVER=8.8.8.8
EOF
    run bash -c "cd '$EJPATH/preset/$ENGAGEMENT' && bash '$REPO_ROOT/preset/preset.sh'"
}

# ---------------------------------------------------------------------------
# STATIC config
# ---------------------------------------------------------------------------

@test "CONFIG=STATIC configures interface with the static IP address" {
    run_preset STATIC
    [[ "$output" == *"MOCK:ifconfig eth0 192.168.1.100"* ]]
}

@test "CONFIG=static (lowercase) configures interface with the static IP address" {
    run_preset static
    [[ "$output" == *"MOCK:ifconfig eth0 192.168.1.100"* ]]
}

@test "CONFIG=STATIC adds the default route via the configured gateway" {
    run_preset STATIC
    [[ "$output" == *"MOCK:route add default gw 192.168.1.1"* ]]
}

@test "CONFIG=STATIC eventually executes the payload" {
    run_preset STATIC
    [[ "$output" == *"payload executed"* ]]
}

@test "CONFIG=STATIC logs configuration details to ej.log" {
    run_preset STATIC
    [ -f "$EJPATH/preset/$ENGAGEMENT/ej.log" ]
    grep -q "192.168.1.100" "$EJPATH/preset/$ENGAGEMENT/ej.log"
}

# ---------------------------------------------------------------------------
# DHCP config
# ---------------------------------------------------------------------------

@test "CONFIG=DHCP starts NetworkManager for DHCP lease acquisition" {
    run_preset DHCP
    [[ "$output" == *"MOCK:systemctl start NetworkManager"* ]]
}

@test "CONFIG=dhcp (lowercase) starts NetworkManager" {
    run_preset dhcp
    [[ "$output" == *"MOCK:systemctl start NetworkManager"* ]]
}

@test "CONFIG=DHCP eventually executes the payload" {
    run_preset DHCP
    [[ "$output" == *"payload executed"* ]]
}

# ---------------------------------------------------------------------------
# Invalid / empty config → shutdown
# ---------------------------------------------------------------------------

@test "CONFIG=invalid triggers shutdown" {
    run_preset BADCONFIG
    [[ "$output" == *"Invalid"* ]] || [[ "$output" == *"SHUTDOWN"* ]]
}

@test "empty CONFIG triggers shutdown" {
    run_preset ""
    [[ "$output" == *"Invalid"* ]] || [[ "$output" == *"SHUTDOWN"* ]]
}
