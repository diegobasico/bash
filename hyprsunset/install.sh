#!/bin/bash

CURRENT_DIR="$(dirname "${BASH_SOURCE[0]}")"
BASENAME="set-hyprsunset"

BIN_DIR="$HOME/.local/bin/"
BIN_PATH="$BIN_DIR/$BASENAME.sh"

SYSTEMD_DIR="$HOME/.config/systemd/user"
SERVICE_PATH="$SYSTEMD_DIR/$BASENAME.service"
TIMER_PATH="$SYSTEMD_DIR/$BASENAME.timer"
