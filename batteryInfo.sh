#!/bin/bash

percentage=$(cat /sys/class/power_supply/BAT0/capacity)

if [ "$percentage" -le "20" ]; then
  notify-send -U critical "Battery low please charge: $percentage%"
else
  notify-send "Battery: $percentage%"
fi

