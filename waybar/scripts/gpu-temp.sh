#!/usr/bin/env bash
raw=$(cat /sys/class/drm/card*/device/hwmon/hwmon*/temp1_input 2>/dev/null | head -n1)
pw=$(cat /sys/class/drm/card*/device/hwmon/hwmon*/power1_average 2>/dev/null | head -n1)
if [ -n "$raw" ]; then t=$(( raw / 1000 )); else t="N/A"; fi
if [ -n "$pw" ]; then pw="$(( pw / 1000000 )) W"; else pw="n/a"; fi
printf '{"text":"%s","tooltip":"GPU temperature\\nCurrent: %s°C\\nPower draw: %s"}\n' "$t" "$t" "$pw"
