#!/bin/bash

hour=$(date +%H)
on_hyprland=$(/usr/bin/pgrep -x Hyprland)
active_hyprsunset=$(/usr/bin/pgrep -x hyprsunset)

if [[ $on_hyprland ]]; then
  if [[ $active_hyprsunset ]]; then
    pkill -x hyprsunset
    sleep 1
  fi

  if ((7 <= hour && hour < 18)); then
    hyprsunset --temperature 6500 &
    brightnessctl set 100%
  elif ((18 <= hour && hour < 20)); then
    hyprsunset --temperature 5000 &
    brightnessctl set 70%
  else
    hyprsunset --temperature 4200 &
    brightnessctl set 30%
  fi
fi
