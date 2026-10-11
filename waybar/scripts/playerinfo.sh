#!/usr/bin/env bash
status=$(playerctl status 2>/dev/null)
if [ "$status" != "Playing" ] && [ "$status" != "Paused" ]; then
    echo ""
    exit 0
fi
info=$(playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null | sed 's/^ - //' | cut -c1-30)
info=${info^^}
info=$(printf '%s' "$info" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
echo "&lt; $info &gt;"
