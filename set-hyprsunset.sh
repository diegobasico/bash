#!/bin/bash

UNIT_DIR="$HOME/.config/systemd/user"
SERVICE_FILE="$UNIT_DIR/set-hyprsunset.service"
TIMER_FILE="$UNIT_DIR/set-hyprsunset.timer"

install_service() {
  echo "📦 Installing user service and timer..."
  mkdir -p "$UNIT_DIR"

  cat >"$SERVICE_FILE" <<EOF
[Unit]
Description=Display Temperature and Brightness Cycle
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=$HOME/Canotila/bash/set-hyprsunset.sh
Environment="XDG_RUNTIME_DIR=/run/user/1000"
Environment="WAYLAND_DISPLAY=wayland-1"

[Install]
WantedBy=default.target
EOF

  cat >"$TIMER_FILE" <<EOF
[Unit]
Description=Run display cycle every 30 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=30min
Persistent=true

[Install]
WantedBy=timers.target
EOF

  systemctl --user daemon-reexec
  systemctl --user daemon-reload
  systemctl --user enable --now set-hyprsunset.timer

  echo "✅ Installed and started set-hyprsunset.timer"
}

run_logic() {
  hour=$(date +%H)
  if pgrep -x Hyprland; then
    case "$hour" in
    0[7-9] | 1[0-7])
      hyprctl hyprsunset temperature 6500
      ;;
    1[8-9])
      hyprctl hyprsunset temperature 5000
      ;;
    *)
      hyprctl hyprsunset temperature 4200
      ;;
    esac
  fi
}

# Entry point
case "$1" in
--install)
  install_service
  ;;
*)
  run_logic
  ;;
esac
