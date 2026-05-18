#!/usr/bin/env bats

load 'helpers/common'

# ---------------------------------------------------------------------------
# EtherJack.conf
# ---------------------------------------------------------------------------

@test "EtherJack.conf can be sourced without errors" {
    run bash -c "source '$REPO_ROOT/EtherJack.conf'"
    [ "$status" -eq 0 ]
}

@test "EtherJack.conf defines EJPATH" {
    source "$REPO_ROOT/EtherJack.conf"
    [ -n "$EJPATH" ]
}

@test "EtherJack.conf PKTS is a positive integer" {
    source "$REPO_ROOT/EtherJack.conf"
    [[ "$PKTS" =~ ^[0-9]+$ ]]
    [ "$PKTS" -gt 0 ]
}

@test "EtherJack.conf defines TESTIP" {
    source "$REPO_ROOT/EtherJack.conf"
    [ -n "$TESTIP" ]
}

@test "EtherJack.conf TESTIP is a valid IPv4 address" {
    source "$REPO_ROOT/EtherJack.conf"
    [[ "$TESTIP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "EtherJack.conf defines TESTPORT" {
    source "$REPO_ROOT/EtherJack.conf"
    [ -n "$TESTPORT" ]
}

@test "EtherJack.conf TESTPORT is a valid port number (1-65535)" {
    source "$REPO_ROOT/EtherJack.conf"
    [[ "$TESTPORT" =~ ^[0-9]+$ ]]
    [ "$TESTPORT" -ge 1 ]
    [ "$TESTPORT" -le 65535 ]
}

# ---------------------------------------------------------------------------
# preset/preset.conf
# ---------------------------------------------------------------------------

@test "preset.conf can be sourced without errors" {
    run bash -c "source '$REPO_ROOT/preset/preset.conf'"
    [ "$status" -eq 0 ]
}

@test "preset.conf has CONFIG defined" {
    source "$REPO_ROOT/preset/preset.conf"
    [ -n "$CONFIG" ]
}

@test "preset.conf CONFIG is a recognised value (dhcp or static)" {
    source "$REPO_ROOT/preset/preset.conf"
    [[ "$CONFIG" =~ ^(dhcp|DHCP|static|STATIC)$ ]]
}

# ---------------------------------------------------------------------------
# wifi/wifi.conf
# ---------------------------------------------------------------------------

@test "wifi.conf can be sourced without errors" {
    run bash -c "source '$REPO_ROOT/wifi/wifi.conf'"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# wifi/hostapd.conf
# ---------------------------------------------------------------------------

@test "hostapd.conf specifies wlan0 as the interface" {
    grep -q "^interface=wlan0" "$REPO_ROOT/wifi/hostapd.conf"
}

@test "hostapd.conf has an ssid field" {
    grep -q "^ssid=" "$REPO_ROOT/wifi/hostapd.conf"
}

@test "hostapd.conf has a wpa_passphrase field" {
    grep -q "^wpa_passphrase=" "$REPO_ROOT/wifi/hostapd.conf"
}

@test "hostapd.conf enables WPA2 (wpa=2)" {
    grep -q "^wpa=2" "$REPO_ROOT/wifi/hostapd.conf"
}

# ---------------------------------------------------------------------------
# EtherJack.service
# ---------------------------------------------------------------------------

@test "EtherJack.service ExecStart points to EtherJack.sh" {
    grep -q "ExecStart=.*EtherJack.sh" "$REPO_ROOT/EtherJack.service"
}

# ---------------------------------------------------------------------------
# EtherJack-payload.service
# ---------------------------------------------------------------------------

@test "EtherJack-payload.service file exists" {
    [ -f "$REPO_ROOT/EtherJack-payload.service" ]
}

@test "EtherJack-payload.service ExecStart references ej_callback" {
    grep -q "ExecStart=.*ej_callback" "$REPO_ROOT/EtherJack-payload.service"
}

@test "EtherJack-payload.service is Type=oneshot" {
    grep -q "^Type=oneshot" "$REPO_ROOT/EtherJack-payload.service"
}

@test "EtherJack-payload.service is WantedBy=multi-user.target" {
    grep -q "WantedBy=multi-user.target" "$REPO_ROOT/EtherJack-payload.service"
}

# ---------------------------------------------------------------------------
# Script permissions and shebangs
# ---------------------------------------------------------------------------

@test "all shell scripts are executable" {
    local scripts=(
        "$REPO_ROOT/EtherJack.sh"
        "$REPO_ROOT/lan/netfinder.sh"
        "$REPO_ROOT/lan/routefinder.sh"
        "$REPO_ROOT/preset/preset.sh"
        "$REPO_ROOT/wifi/wifi.sh"
    )
    for script in "${scripts[@]}"; do
        [ -x "$script" ]
    done
}

@test "all shell scripts declare a bash shebang" {
    local scripts=(
        "$REPO_ROOT/EtherJack.sh"
        "$REPO_ROOT/lan/netfinder.sh"
        "$REPO_ROOT/lan/routefinder.sh"
        "$REPO_ROOT/preset/preset.sh"
        "$REPO_ROOT/wifi/wifi.sh"
    )
    for script in "${scripts[@]}"; do
        head -1 "$script" | grep -q "#!/bin/bash"
    done
}

@test "ejmotd file exists" {
    [ -f "$REPO_ROOT/files/ejmotd" ]
}
