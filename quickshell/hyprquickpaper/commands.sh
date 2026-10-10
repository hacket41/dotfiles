#!/bin/bash

awww img "$1" -t grow --transition-duration 1
mkdir -p ~/.cache && echo "$1" >~/.cache/current-wallpaper
