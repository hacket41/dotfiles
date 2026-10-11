#!/usr/bin/env bash
# CAVA visualizer for waybar. Usage: cava.sh left|right
# The right instance is drawn in reverse so the two sides mirror each other.

side="${1:-left}"
bars=16
cfg="/tmp/waybar-cava-$side.conf"

reverse=0
[ "$side" = "right" ] && reverse=1

# stop any stale instance of this side
pkill -f "cava -p $cfg" 2>/dev/null

cat > "$cfg" <<EOF
[general]
bars = $bars
framerate = 30

[input]
method = pipewire
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
bar_delimiter = 59
reverse = $reverse
EOF

# digits 0-7 -> block characters, drop ';' delimiters, blank line when silent
dict="s/;//g;s/0/▁/g;s/1/▂/g;s/2/▃/g;s/3/▄/g;s/4/▅/g;s/5/▆/g;s/6/▇/g;s/7/█/g"

trap 'pkill -P $$; exit' TERM INT EXIT

cava -p "$cfg" | sed -u "$dict" &
wait
