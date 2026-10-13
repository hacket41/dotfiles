#!/usr/bin/env bash
# Wi-Fi menu for iwd (iwctl), styled like the other rofi menus
theme="$HOME/.config/rofi/launchers/type-1/style-5.rasi"

dev=$(ls /sys/class/net | grep -m1 '^w')
if [ -z "$dev" ]; then
    notify-send -u critical -i network-error "Wi-Fi" "No wireless device found"
    exit 1
fi

strip() { sed 's/\x1b\[[0-9;]*[A-Za-z]//g'; }

# icons written as codepoints so they survive copy/paste
ic_off=$'\U000f05aa'
ic_refresh=$'\U000f0450'
ic_lock=$'\U000f033e'
ic_s4=$'\U000f0928'
ic_s3=$'\U000f0925'
ic_s2=$'\U000f0922'
ic_s1=$'\U000f091f'

rofi_menu() {
    rofi -dmenu -i -format i -p "$1" -theme "$theme" \
        -theme-str 'window { width: 600px; }'
}

# radio off: offer to turn it on
if [ $(($(cat /sys/class/net/$dev/flags) & 1)) -eq 0 ]; then
    choice=$(printf '%s\n' "$ic_off  Turn Wi-Fi on" | rofi_menu "Wi-Fi")
    [ -z "$choice" ] && exit 0
    rfkill unblock wifi
    iwctl device "$dev" set-property Powered on
    notify-send -i network-wireless "Wi-Fi" "Turning on..."
    sleep 3
    exec "$0"
fi

iwctl station "$dev" scan >/dev/null 2>&1
sleep 2

connected=$(iwctl station "$dev" show | strip | sed -n 's/^ *Connected network *//p' | sed 's/ *$//')

lines=("$ic_refresh  Rescan" "$ic_off  Turn Wi-Fi off")
actions=("rescan" "off")
ssids=("" "")
secs=("" "")

while IFS='|' read -r cur ssid sec stars; do
    case ${#stars} in
    4 | 5) icon=$ic_s4 ;;
    3) icon=$ic_s3 ;;
    2) icon=$ic_s2 ;;
    *) icon=$ic_s1 ;;
    esac
    lock=""
    [ "$sec" != "open" ] && lock="  $ic_lock"
    if [ "$ssid" = "$connected" ]; then
        lines+=("$icon  $ssid$lock   (connected)")
        actions+=("down")
    else
        lines+=("$icon  $ssid$lock")
        actions+=("up")
    fi
    ssids+=("$ssid")
    secs+=("$sec")
done < <(iwctl station "$dev" get-networks | strip |
    sed -E 's/^[[:space:]]*(>)?[[:space:]]*(.*[^[:space:]])[[:space:]]+(open|psk|8021x|wep)[[:space:]]+(\*+)[[:space:]]*$/\1|\2|\3|\4/' |
    grep -E '^[^|]*\|.+\|(open|psk|8021x|wep)\|\*+$')

idx=$(printf '%s\n' "${lines[@]}" | rofi_menu "Wi-Fi")
[ -z "$idx" ] && exit 0
ssid="${ssids[$idx]}"
sec="${secs[$idx]}"

case "${actions[$idx]}" in
rescan)
    exec "$0"
    ;;
off)
    iwctl device "$dev" set-property Powered off
    notify-send -i network-wireless-offline "Wi-Fi" "Turned off"
    ;;
down)
    iwctl station "$dev" disconnect
    notify-send -i network-wireless "Wi-Fi" "Disconnected from $ssid"
    ;;
up)
    if [ "$sec" = "8021x" ]; then
        notify-send -u critical -i network-error "Wi-Fi" \
            "$ssid is an enterprise network; configure it with iwctl by hand"
        exit 1
    fi
    known=$(iwctl known-networks list | strip | awk -v s="$ssid" \
        '{sub(/^[ \t]+/,"")} index($0,s)==1 {print "yes"; exit}')
    if [ "$sec" = "open" ] || [ "$known" = "yes" ]; then
        out=$(iwctl station "$dev" connect "$ssid" 2>&1)
    else
        pw=$(rofi -dmenu -password -mesg "Password for $ssid" -theme "$theme" \
            -theme-str 'mainbox { children: [ "inputbar", "message" ]; }
                textbox-prompt-colon { str: ">"; }
                entry { placeholder: "Password"; }' </dev/null)
        [ -z "$pw" ] && exit 0
        out=$(iwctl --passphrase "$pw" station "$dev" connect "$ssid" 2>&1)
    fi
    # wait up to 10 seconds for the connection to come up
    now=""
    for i in $(seq 10); do
        now=$(iwctl station "$dev" show | strip | sed -n 's/^ *Connected network *//p' | sed 's/ *$//')
        [ "$now" = "$ssid" ] && break
        sleep 1
    done
    if [ "$now" = "$ssid" ]; then
        notify-send -i network-wireless "Wi-Fi" "Connected to $ssid"
    else
        notify-send -u critical -i network-error "Wi-Fi" \
            "Couldn't connect to $ssid: ${out:-wrong password?}"
    fi
    ;;
esac
