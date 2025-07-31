#!/usr/bin/env bash

# define levels and paths
low=20
lower=10
critical=5
state_file="$XDG_CACHE_HOME/battery-notification.state"
battery_path="/sys/class/power_supply/BAT1"

# checks if ".local/cache" and "battery_path" exists
mkdir -p "$(dirname "$state_file")"
[[ ! -d $battery_path ]] && exit 1

remaining_capacity=$(cat "$battery_path/capacity")
battery_status=$(cat "$battery_path/status")

# checks for last_state file content
last_state="none"
[[ -f "$state_file" ]] && last_state=$(<"$state_file")

#functions are easier to debug
check_battery() {

  if [[ "$battery_status" == "Discharging" ]]; then
    if [[ "$remaining_capacity" -le "$critical" ]] && [[ "$last_state" != "critical" ]]; then
      notify-send -u critical "⚠️ Critical Low Battery" "Battery is at ${remaining_capacity}%"
      echo "critical" >"$state_file"

    elif [[ "$remaining_capacity" -le "$lower" ]] && [[ "$last_state" != "lower" ]]; then
      notify-send -u critical "🪫 Very Low Battery" "Battery is at ${remaining_capacity}%"
      echo "lower" >"$state_file"

    elif [[ "$remaining_capacity" -le "$low" ]] && [[ "$last_state" != "low" ]]; then
      notify-send -u critical "🪫 Low Battery" "Battery is at ${remaining_capacity}%"
      echo "low" >"$state_file"

    elif [[ "$remaining_capacity" -gt "$low" ]] && [[ "$last_state" != "high" ]]; then
      notify-send "🔋 Disconnected" "Battery is at ${remaining_capacity}%"
      echo "high" >"$state_file"

    fi

  elif [[ "$battery_status" == "Charging" ]] && [[ "$last_state" != "charging" ]]; then
    notify-send "🔌 Charging" "Device is charging now."
    echo "charging" >"$state_file"
  elif [[ "$battery_status" == "Full" ]] && [[ "$last_state" != "Full" ]]; then
    notify-send "🔋 Full Charge" "Device is fully charged."
    echo "full" >"$state_file"
  fi
}

check_battery
