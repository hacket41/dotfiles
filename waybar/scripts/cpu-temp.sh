#!/usr/bin/env bash
t="N/A"
for h in /sys/class/hwmon/hwmon*; do
  if [ "$(cat "$h/name" 2>/dev/null)" = "k10temp" ]; then
    t=$(( $(cat "$h/temp1_input") / 1000 ))
    break
  fi
done
f=$(awk '/cpu MHz/ {s+=$4; n++} END {if (n) printf "%.2f", s/n/1000}' /proc/cpuinfo)
printf '{"text":"%s","tooltip":"CPU: Ryzen 7 PRO 6850H\\nTemperature: %s°C\\nAvg clock: %s GHz"}\n' "$t" "$t" "${f:-n/a}"
