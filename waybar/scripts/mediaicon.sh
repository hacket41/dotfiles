#!/usr/bin/env bash
case "$(playerctl status 2>/dev/null)" in
Playing) echo $'\uf04c' ;; # pause icon: music is playing
Paused) echo $'\uf04b' ;;  # play icon: music is paused
*) echo $'\uf001' ;;       # music note: no player
esac
