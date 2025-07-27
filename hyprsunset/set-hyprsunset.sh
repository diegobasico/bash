#!/bin/bash

hour=$(date +%H)
on_hyprland=$(/usr/bin/pgrep -x Hyprland || true)
on_hyprsunset=$(/usr/bin/pgrep -x hyprsunset || true)

if ! [[ $on_hyprsunset ]]; then

  hyprsunset &

fi

if [[ $on_hyprland ]]; then

  if ((7 <= hour && hour < 18)); then
    hyprctl hyprsunset temperature 6500
  elif ((18 <= hour && hour < 21)); then
    hyprctl hyprsunset temperature 5000
  else
    hyprctl hyprsunset temperature 4200
  fi

fi
