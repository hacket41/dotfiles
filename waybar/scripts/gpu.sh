#!/usr/bin/env bash
busy=$(cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -n1)
vu=$(cat /sys/class/drm/card*/device/mem_info_vram_used 2>/dev/null | head -n1)
vt=$(cat /sys/class/drm/card*/device/mem_info_vram_total 2>/dev/null | head -n1)
clk=$(grep '\*' /sys/class/drm/card*/device/pp_dpm_sclk 2>/dev/null | head -n1 | awk '{print $2}')
vu=$(( ${vu:-0} / 1048576 ))
vt=$(( ${vt:-0} / 1048576 ))
printf '{"text":"%s","tooltip":"GPU: AMD Radeon 680M\\nUsage: %s%%\\nVRAM: %s / %s MiB\\nClock: %s"}\n' \
  "${busy:-N/A}" "${busy:-N/A}" "$vu" "$vt" "${clk:-n/a}"
