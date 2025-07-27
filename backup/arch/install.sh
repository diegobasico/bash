#!/usr/bin/env bash

set -e

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_NAME="update-package-list"
INSTALL_PATH="/usr/local/bin/$BASE_NAME"

echo ":: Creating backup-packages.hook..."
mkdir -p /etc/pacman.d/hooks
cat >/etc/pacman.d/hooks/backup-packages.hook <<EOF
[Trigger]
Operation = Install
Operation = Remove
Type = Package
Target = *

[Action]
Description = Updating package backup lists...
When = PostTransaction
Exec = $INSTALL_PATH
EOF

echo ":: Installing hook script..."
sed "s|__INSTALL_DIR__|$BASE_DIR|" "$BASE_DIR/$BASE_NAME" >"$INSTALL_PATH"
chmod +x "$INSTALL_PATH"

echo "✔ Hook and binary installed successfully."
