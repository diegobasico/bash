#!/usr/bin/env bash

# Check for Hyprland session
[[ $XDG_CURRENT_DESKTOP != "Hyprland" ]] && exit 0

# Define battery thresholds and paths
low=20
lower=10
critical=5
state_file="$XDG_CACHE_HOME/battery-notification.state"
log_file="$XDG_CACHE_HOME/battery-notification.log"
battery_path="/sys/class/power_supply/BAT1"

# Ensure cache and battery path exist
mkdir -p "$(dirname "$state_file")"
[[ ! -d $battery_path ]] && exit 1

# Read current battery capacity and status
read -r remaining_capacity <"$battery_path/capacity"
read -r battery_status <"$battery_path/status"

# Load last notification state
last_state="none"
[[ -f "$state_file" ]] && last_state=$(<"$state_file")

set_state() {
  new_state=$1
  echo "$new_state" >"$state_file"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Battery: $remaining_capacity% - Status: $battery_status - State: $new_state" >>"$log_file"
}

check_battery() {
  case "$battery_status" in
  "Discharging")
    if ((remaining_capacity <= critical)); then
      if [[ $last_state != "critical" ]]; then
        notify-send -u critical "⚠️ Critical Battery Level" "Battery is at ${remaining_capacity}%"
        set_state "critical"
      fi

    elif ((remaining_capacity <= lower)); then
      if [[ $last_state != "lower" ]]; then
        notify-send -u critical "🪫 Very Low Battery" "Battery is at ${remaining_capacity}%"
        set_state "lower"
      fi
    elif ((remaining_capacity <= low)); then
      if [[ $last_state != "low" ]]; then
        notify-send -u critical "🪫 Low Battery" "Battery is at ${remaining_capacity}%"
        set_state "low"
      fi
    elif ((remaining_capacity > low)); then
      if [[ $last_state != "high" ]]; then
        notify-send "🔋 Disconnected" "Battery is at ${remaining_capacity}%"
        set_state "high"
      fi
    fi
    ;;

  "Charging" | "Unknown" | "Not charging")
    if ((remaining_capacity >= 100)) && [[ $last_state != "full" && $last_state != "charging" ]]; then
      notify-send "🔋 Full Charge" "Device is fully charged."
      set_state "full"

    elif ((remaining_capacity < 100)) && [[ $last_state != "charging" ]]; then
      notify-send "🔌 Charging" "Device is charging now."
      set_state "charging"
    fi
    ;;

  "Full")
    if [[ $last_state != "full" ]]; then
      notify-send "🔋 Full Charge" "Device is fully charged."
      set_state "full"
    fi
    ;;
  esac
}

check_battery
