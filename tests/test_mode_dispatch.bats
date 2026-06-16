#!/usr/bin/env bats
#
# Tests for EtherJack.sh mode dispatching.
#
# Strategy: mirror the real directory structure inside BATS_TEST_TMPDIR,
# replace sub-scripts with stubs that just print their name, mock `init`
# so shutdown calls don't touch the real system, then run EtherJack.sh
# from the temp EJPATH (the script sources EtherJack.conf relative to CWD).

load 'helpers/common'

setup() {
    export EJPATH="$BATS_TEST_TMPDIR/ej"
    mkdir -p "$EJPATH/lan" "$EJPATH/wifi" "$EJPATH/preset" "$EJPATH/files" "$EJPATH/bin"

    # Provide ejmotd so the cat command in each mode branch doesn't error
    cp "$REPO_ROOT/files/ejmotd" "$EJPATH/files/ejmotd" 2>/dev/null ||
        touch "$EJPATH/files/ejmotd"

    # Lightweight sub-script stubs
    for entry in "lan/netfinder.sh:netfinder" "wifi/wifi.sh:wifi" "preset/preset.sh:preset"; do
        local path="${entry%%:*}"
        local name="${entry##*:}"
        printf '#!/bin/bash\necho "%s called"\n' "$name" >"$EJPATH/$path"
        chmod +x "$EJPATH/$path"
    done

    # Mock bin: init must be intercepted before the real /sbin/init runs
    export MOCK_BIN="$BATS_TEST_TMPDIR/bin"
    mkdir -p "$MOCK_BIN"
    cat >"$MOCK_BIN/init" <<'EOF'
#!/bin/bash
echo "SHUTDOWN: init $*"
exit 0
EOF
    chmod +x "$MOCK_BIN/init"
    export PATH="$MOCK_BIN:$PATH"

    # Minimal EtherJack.conf — EJMODE left blank; each test fills it via run_ej()
    cat >"$EJPATH/EtherJack.conf" <<EOF
EJMODE=
EJPATH=$EJPATH
ENGAGEMENT=eng001
EJLOG=ej.log
EJEXE=
CALLHOME=
PKTS=5
TESTIP=93.184.216.34
TESTPORT=80
EOF

    cp "$REPO_ROOT/EtherJack.sh" "$EJPATH/EtherJack.sh"
}

# Helper: set EJMODE and run EtherJack.sh from EJPATH so the relative
# `source EtherJack.conf` inside the script resolves correctly.
run_ej() {
    local mode="$1"
    sed -i "s/^EJMODE=.*/EJMODE=$mode/" "$EJPATH/EtherJack.conf"
    run bash -c "cd '$EJPATH' && bash EtherJack.sh"
}

# ---------------------------------------------------------------------------
# LAN mode
# ---------------------------------------------------------------------------

@test "EJMODE=LAN dispatches to netfinder.sh" {
    run_ej LAN
    [ "$status" -eq 0 ]
    [[ "$output" == *"netfinder called"* ]]
}

@test "EJMODE=lan (lowercase) dispatches to netfinder.sh" {
    run_ej lan
    [ "$status" -eq 0 ]
    [[ "$output" == *"netfinder called"* ]]
}

# ---------------------------------------------------------------------------
# WIFI mode
# ---------------------------------------------------------------------------

@test "EJMODE=WIFI dispatches to wifi.sh" {
    run_ej WIFI
    [ "$status" -eq 0 ]
    [[ "$output" == *"wifi called"* ]]
}

@test "EJMODE=wifi (lowercase) dispatches to wifi.sh" {
    run_ej wifi
    [ "$status" -eq 0 ]
    [[ "$output" == *"wifi called"* ]]
}

@test "EJMODE=WiFi (mixed case) dispatches to wifi.sh" {
    run_ej WiFi
    [ "$status" -eq 0 ]
    [[ "$output" == *"wifi called"* ]]
}

# ---------------------------------------------------------------------------
# PRESET mode
# ---------------------------------------------------------------------------

@test "EJMODE=PRESET dispatches to preset.sh" {
    run_ej PRESET
    [ "$status" -eq 0 ]
    [[ "$output" == *"preset called"* ]]
}

@test "EJMODE=preset (lowercase) dispatches to preset.sh" {
    run_ej preset
    [ "$status" -eq 0 ]
    [[ "$output" == *"preset called"* ]]
}

# ---------------------------------------------------------------------------
# Invalid / empty mode → shutdown
# ---------------------------------------------------------------------------

@test "empty EJMODE prints invalid mode message and triggers shutdown" {
    run_ej ""
    [[ "$output" == *"Invalid mode"* ]]
    [[ "$output" == *"SHUTDOWN"* ]]
}

@test "unrecognised EJMODE prints invalid mode message and triggers shutdown" {
    run_ej BADMODE
    [[ "$output" == *"Invalid mode"* ]]
    [[ "$output" == *"SHUTDOWN"* ]]
}

# ---------------------------------------------------------------------------
# Engagement directory creation
# ---------------------------------------------------------------------------

@test "LAN mode creates an engagement directory under lan/" {
    run_ej LAN
    [ -d "$EJPATH/lan/eng001" ]
}

@test "WIFI mode creates an engagement directory under wifi/" {
    run_ej WIFI
    [ -d "$EJPATH/wifi/eng001" ]
}

@test "PRESET mode creates an engagement directory under preset/" {
    run_ej PRESET
    [ -d "$EJPATH/preset/eng001" ]
}
