#!/bin/bash

# Display Temperature and Brightness Cycle Script
# This script can install itself as a systemd service and timer

SCRIPT_NAME="display-cycle"
SCRIPT_DIR="$HOME/.local/bin"
SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_NAME.sh"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
SERVICE_FILE="$SYSTEMD_USER_DIR/$SCRIPT_NAME.service"
TIMER_FILE="$SYSTEMD_USER_DIR/$SCRIPT_NAME.timer"

# Function to run the display cycle logic
run_display_cycle() {
  # Get current hour
  hour=$(date +%H)

  # Check if we're running Hyprland
  on_hyprland=$(/usr/bin/pgrep -x Hyprland)

  # Check if hyprsunset is already running
  active_hyprsunset=$(/usr/bin/pgrep -x hyprsunset)

  # Only proceed if we're on Hyprland
  if [[ $on_hyprland ]]; then
    # Kill existing hyprsunset if running
    if [[ $active_hyprsunset ]]; then
      pkill -x hyprsunset
      sleep 1
    fi

    # Set temperature and brightness based on time
    if ((7 <= hour && hour < 18)); then
      # Day time: warm white
      hyprsunset --temperature 6500 &
      brightnessctl set 100%
      echo "$(date): Day mode - 6500K, 100% brightness"
    elif ((18 <= hour && hour < 20)); then
      # Evening: slightly warm
      hyprsunset --temperature 5000 &
      brightnessctl set 70%
      echo "$(date): Evening mode - 5000K, 70% brightness"
    else
      # Night: warm/red
      hyprsunset --temperature 4200 &
      brightnessctl set 30%
      echo "$(date): Night mode - 4200K, 30% brightness"
    fi
  else
    echo "$(date): Hyprland not running, skipping display cycle"
  fi
}

# Function to create systemd service file
create_service_file() {
  cat >"$SERVICE_FILE" <<EOF
[Unit]
Description=Display Temperature and Brightness Cycle
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH run
Environment=DISPLAY=:0
Environment=WAYLAND_DISPLAY=wayland-0
EOF
}

# Function to create systemd timer file
create_timer_file() {
  cat >"$TIMER_FILE" <<EOF
[Unit]
Description=Run display cycle every 10 minutes
Requires=$SCRIPT_NAME.service

[Timer]
OnBootSec=1min
OnUnitActiveSec=10min
Persistent=true

[Install]
WantedBy=timers.target
EOF
}

# Function to install the script and systemd files
install_service() {
  echo "Installing $SCRIPT_NAME service..."

  # Create directories
  mkdir -p "$SCRIPT_DIR"
  mkdir -p "$SYSTEMD_USER_DIR"

  # Copy script to local bin (if not already there)
  if [[ "$(realpath "$0")" != "$SCRIPT_PATH" ]]; then
    cp "$0" "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"
    echo "✓ Copied script to $SCRIPT_PATH"
  else
    echo "✓ Script already in correct location"
  fi

  # Create service and timer files
  create_service_file
  create_timer_file
  echo "✓ Created service and timer files"

  # Reload systemd and enable timer
  systemctl --user daemon-reload
  systemctl --user enable "$SCRIPT_NAME.timer"
  systemctl --user start "$SCRIPT_NAME.timer"

  echo "✓ Enabled and started $SCRIPT_NAME.timer"
  echo ""
  echo "Installation complete! The service will run every 10 minutes."
  echo "You can check status with: systemctl --user status $SCRIPT_NAME.timer"
}

# Function to uninstall the service
uninstall_service() {
  echo "Uninstalling $SCRIPT_NAME service..."

  # Stop and disable timer
  systemctl --user stop "$SCRIPT_NAME.timer" 2>/dev/null
  systemctl --user disable "$SCRIPT_NAME.timer" 2>/dev/null

  # Remove files
  rm -f "$SERVICE_FILE" "$TIMER_FILE"

  # Reload systemd
  systemctl --user daemon-reload

  echo "✓ Uninstalled $SCRIPT_NAME service"
  echo "Note: Script file remains at $SCRIPT_PATH"
}

# Function to show status
show_status() {
  echo "=== $SCRIPT_NAME Status ==="
  echo "Script location: $SCRIPT_PATH"
  echo "Service file: $SERVICE_FILE"
  echo "Timer file: $TIMER_FILE"
  echo ""

  if systemctl --user is-active --quiet "$SCRIPT_NAME.timer"; then
    echo "✓ Timer is active"
    systemctl --user status "$SCRIPT_NAME.timer" --no-pager -l
  else
    echo "✗ Timer is not active"
  fi
}

# Function to show help
show_help() {
  echo "Usage: $0 [COMMAND]"
  echo ""
  echo "Commands:"
  echo "  run         Run the display cycle once"
  echo "  install     Install as systemd service and timer"
  echo "  uninstall   Remove systemd service and timer"
  echo "  status      Show service status"
  echo "  help        Show this help message"
  echo ""
  echo "If no command is given, 'run' is assumed."
}

# Main script logic
case "${1:-run}" in
"run")
  run_display_cycle
  ;;
"install")
  install_service
  ;;
"uninstall")
  uninstall_service
  ;;
"status")
  show_status
  ;;
"help" | "--help" | "-h")
  show_help
  ;;
*)
  echo "Unknown command: $1"
  show_help
  exit 1
  ;;
esac
