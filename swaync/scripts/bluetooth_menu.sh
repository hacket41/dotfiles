#!/usr/bin/env bash
# Bluetooth picker for swaync's menubar "Connect Device…" action.
# Requires: rofi, bluez (bluetoothctl)
set -euo pipefail

command -v rofi >/dev/null 2>&1 || {
    notify-send "Bluetooth" "rofi is not installed"
    exit 1
}
command -v bluetoothctl >/dev/null 2>&1 || {
    notify-send "Bluetooth" "bluetoothctl not found"
    exit 1
}

bluetoothctl power on >/dev/null 2>&1 || true

# Scan and capture [NEW] Device lines directly from scan output, since
# `bluetoothctl devices` alone can miss devices bluetoothd hasn't cached yet.
scan_output="$(timeout 6 bluetoothctl scan on 2>&1 || true)"

# Merge already-known/paired devices with anything freshly discovered
mapfile -t lines < <(
    {
        bluetoothctl devices
        grep -oE '\[NEW\] Device ([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2} .*' <<<"$scan_output" | sed -E 's/^\[NEW\] //'
    } | sed -E 's/^Device //' | awk '!seen[$1]++'
)

if [[ ${#lines[@]} -eq 0 ]]; then
    notify-send "Bluetooth" "No devices found. Check that Bluetooth is powered on (bluetoothctl show) and not rfkill-blocked."
    exit 0
fi

menu=""
declare -A name_of
for line in "${lines[@]}"; do
    mac="${line%% *}"
    name="${line#* }"
    name_of["$mac"]="$name"
    state="Disconnected"
    bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes" && state="Connected"
    menu+="${name}  [${state}]  (${mac})"$'\n'
done

chosen="$(printf '%s' "$menu" | rofi -dmenu -i -p "󰂯 Bluetooth" -theme ~/.config/rofi/launchers/type-4/style-1.rasi || true)"
[[ -z "$chosen" ]] && exit 0

mac="$(grep -oE '\(([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}\)' <<<"$chosen" | tr -d '()')"
[[ -z "$mac" ]] && exit 0
name="${name_of[$mac]:-$mac}"

if grep -q '\[Connected\]' <<<"$chosen"; then
    if bluetoothctl disconnect "$mac" >/dev/null 2>&1; then
        notify-send "Bluetooth" "Disconnected $name"
    else
        notify-send -u critical "Bluetooth" "Failed to disconnect $name"
    fi
else
    bluetoothctl pair "$mac" >/dev/null 2>&1 || true
    bluetoothctl trust "$mac" >/dev/null 2>&1 || true
    if bluetoothctl connect "$mac" >/dev/null 2>&1; then
        notify-send "Bluetooth" "Connected to $name"
    else
        notify-send -u critical "Bluetooth" "Failed to connect to $name"
    fi
fi
