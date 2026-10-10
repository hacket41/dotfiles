#!/bin/bash

pkill waybar
waybar &

pkill swaync
swaync &
