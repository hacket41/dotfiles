#!/usr/bin/env bash
theme="$HOME/.config/rofi/launchers/type-1/style-5.rasi"

ic_on=$'\U000f00af'
ic_conn=$'\U000f00b1'
ic_off=$'\U000f00b2'
ic_refresh=$'\U000f0450'

rofi_menu() {
    rofi -dmenu -i -format i -p "$1" -theme "$theme" \
        -theme-str 'window { width: 600px; }'
}

while true; do
    powered=$(bluetoothctl show | awk '/Powered:/ {print $2}')
    if [ "$powered" != "yes" ]; then
        choice=$(printf '%s\n' "$ic_off  Turn Bluetooth on" | rofi_menu "Bluetooth")
        [ -z "$choice" ] && exit 0
        bluetoothctl power on >/dev/null &&
            notify-send -i bluetooth "Bluetooth" "Turned on"
        sleep 1
        continue
    fi

    connected=$(bluetoothctl devices Connected | awk '{print $2}')
    paired=$(bluetoothctl devices Paired | awk '{print $2}')

    lines=("$ic_refresh  Scan for devices" "$ic_off  Turn Bluetooth off")
    actions=("scan" "off")
    macs=("" "")
    names=("" "")

    while read -r _ mac name; do
        [ -z "$mac" ] && continue
        [ "${name//-/:}" = "$mac" ] && continue # skip unnamed devices
        if grep -Fxq "$mac" <<<"$connected"; then
            lines+=("$ic_conn  $name   [connected]")
        elif grep -Fxq "$mac" <<<"$paired"; then
            lines+=("$ic_on  $name   [paired]")
        else
            lines+=("$ic_on  $name   [new]")
        fi
        actions+=("dev")
        macs+=("$mac")
        names+=("$name")
    done < <(bluetoothctl devices)

    idx=$(printf '%s\n' "${lines[@]}" | rofi_menu "Bluetooth")
    [ -z "$idx" ] && exit 0
    mac="${macs[$idx]}"
    name="${names[$idx]}"

    case "${actions[$idx]}" in
    scan)
        notify-send -i bluetooth "Bluetooth" "Scanning for 8 seconds..."
        bluetoothctl --timeout 8 scan on >/dev/null 2>&1
        continue
        ;;
    off)
        bluetoothctl power off >/dev/null
        notify-send -i bluetooth "Bluetooth" "Turned off"
        exit 0
        ;;
    dev)
        if grep -Fxq "$mac" <<<"$connected"; then
            bluetoothctl disconnect "$mac" >/dev/null &&
                notify-send -i bluetooth "Bluetooth" "Disconnected from $name"
        else
            if ! grep -Fxq "$mac" <<<"$paired"; then
                timeout 25 bluetoothctl pair "$mac" >/dev/null 2>&1 &&
                    bluetoothctl trust "$mac" >/dev/null
            fi
            if timeout 15 bluetoothctl connect "$mac" >/dev/null 2>&1; then
                notify-send -i bluetooth "Bluetooth" "Connected to $name"
            else
                notify-send -u critical -i bluetooth "Bluetooth" "Couldn't connect to $name"
            fi
        fi
        exit 0
        ;;
    esac
done
