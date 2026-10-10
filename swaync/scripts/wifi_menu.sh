#!/usr/bin/env bash
# Wi-Fi picker for swaync's menubar "Connect to Network…" action.
# Requires: rofi, NetworkManager (nmcli)
set -euo pipefail

command -v rofi >/dev/null 2>&1 || {
    notify-send "Wi-Fi" "rofi is not installed"
    exit 1
}
command -v nmcli >/dev/null 2>&1 || {
    notify-send "Wi-Fi" "nmcli/NetworkManager not found"
    exit 1
}

nmcli radio wifi on >/dev/null 2>&1 || true
nmcli device wifi rescan >/dev/null 2>&1 || true
sleep 1.5

# SSID:SECURITY:SIGNAL:IN-USE, de-duplicated by SSID, skip hidden/empty SSIDs
mapfile -t rows < <(nmcli -t -f IN-USE,SSID,SECURITY,SIGNAL device wifi list |
    awk -F: '$2 != "" && !seen[$2]++')

if [[ ${#rows[@]} -eq 0 ]]; then
    notify-send "Wi-Fi" "No networks found"
    exit 0
fi

menu=""
declare -A sec_of
for row in "${rows[@]}"; do
    IFS=: read -r inuse ssid security signal <<<"$row"
    sec_of["$ssid"]="$security"
    mark=" "
    [[ "$inuse" == "*" ]] && mark=""
    lock=""
    [[ -n "$security" && "$security" != "--" ]] && lock=" 󰌾"
    menu+="${mark}${ssid}${lock}  (${signal}%)"$'\n'
done

chosen="$(printf '%s' "$menu" | rofi -dmenu -i -p "󰤨 Wi-Fi" -theme ~/.config/rofi/launchers/type-4/style-1.rasi || true)"
[[ -z "$chosen" ]] && exit 0

# Strip the trailing lock glyph + signal strength, and leading connected mark
ssid="$(sed -E 's/^ //; s/ 󰌾?  \([0-9]+%\)$//' <<<"$chosen")"

if nmcli -t -f NAME connection show | grep -qxF "$ssid"; then
    if nmcli connection up "$ssid" >/dev/null 2>&1; then
        notify-send "Wi-Fi" "Connected to $ssid"
    else
        notify-send -u critical "Wi-Fi" "Failed to connect to $ssid"
    fi
    exit 0
fi

security="${sec_of[$ssid]:-}"
if [[ -n "$security" && "$security" != "--" ]]; then
    pass="$(rofi -dmenu -password -p "Password for $ssid" -theme ~/.config/rofi/launchers/type-4/style-1.rasi || true)"
    [[ -z "$pass" ]] && exit 0
    if nmcli device wifi connect "$ssid" password "$pass" >/dev/null 2>&1; then
        notify-send "Wi-Fi" "Connected to $ssid"
    else
        notify-send -u critical "Wi-Fi" "Failed to connect to $ssid (check password)"
    fi
else
    if nmcli device wifi connect "$ssid" >/dev/null 2>&1; then
        notify-send "Wi-Fi" "Connected to $ssid"
    else
        notify-send -u critical "Wi-Fi" "Failed to connect to $ssid"
    fi
fi
