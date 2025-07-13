#!/bin/bash

hour=$(date +%H)
on_hyprland=$(/usr/bin/pgrep -x Hyprland)

if [[ $on_hyprland ]]; then

  if ((7 <= hour && hour < 18)); then
    hyprctl hyprsunset temperature 6500
  elif ((18 <= hour && hour < 20)); then
    hyprctl hyprsunset temperature 5000
  else
    hyprctl hyprsunset temperature 4200
  fi

fi
