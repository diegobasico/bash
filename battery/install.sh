#!/usr/bin/env bash
set -e

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASENAME="battery-notification"

BIN_DIR="$HOME/.local/bin"
BIN_PATH="$BIN_DIR/$BASENAME.sh"

SYSTEMD_DIR="$HOME/.config/systemd/user"
SERVICE_PATH="$SYSTEMD_DIR/$BASENAME.service"
TIMER_PATH="$SYSTEMD_DIR/$BASENAME.timer"

echo "Checking required files..."
for file in "$BASENAME.sh" "$BASENAME.service" "$BASENAME.timer"; do
  [[ -f "$CURRENT_DIR/$file" ]] || {
    echo "❌ Missing $file in $CURRENT_DIR" >&2
    exit 1
  }
done

echo "Creating target directories..."
mkdir -p "$BIN_DIR" "$SYSTEMD_DIR"

echo "Copying files..."
cp -v "$CURRENT_DIR/$BASENAME.sh" "$BIN_PATH"
cp -v "$CURRENT_DIR/$BASENAME.service" "$SERVICE_PATH"
cp -v "$CURRENT_DIR/$BASENAME.timer" "$TIMER_PATH"
chmod +x "$BIN_PATH"

echo "Reloading systemd user units..."
systemctl --user daemon-reload

echo "Ensuring timer is active..."
if systemctl --user is-active --quiet "$BASENAME.timer"; then
  echo "Timer is already active, restarting it..."
  systemctl --user restart "$BASENAME.timer"
else
  echo "Timer is not active, enabling and starting it..."
  systemctl --user enable --now "$BASENAME.timer"
fi

echo "✔ Installation complete."
