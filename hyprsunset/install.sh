#!/bin/bash

set -e

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASENAME="set-hyprsunset"

BIN_DIR="$HOME/.local/bin/"
BIN_PATH="$BIN_DIR/$BASENAME.sh"

SYSTEMD_DIR="$HOME/.config/systemd/user"
SERVICE_PATH="$SYSTEMD_DIR/$BASENAME.service"
TIMER_PATH="$SYSTEMD_DIR/$BASENAME.timer"

echo "Checking local bin and systemd folders..."

mkdir -p "$BIN_DIR"
mkdir -p "$SYSTEMD_DIR"

echo "Copying files..."

cp -v "$CURRENT_DIR/$BASENAME.sh" "$BIN_PATH"
cp -v "$CURRENT_DIR/$BASENAME.service" "$SERVICE_PATH"
cp -v "$CURRENT_DIR/$BASENAME.timer" "$TIMER_PATH"
chmod +x "$BIN_PATH"

echo "Reloading systemd daemon..."

systemctl --user daemon-reexec
systemctl --user daemon-reload

echo "Enabling and starting the timer..."

systemctl --user enable --now "$BASENAME.timer"

echo "✔ Installation complete."
