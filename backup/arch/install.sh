#!/usr/bin/env bash

set -e

BASE_DIR="$(dirname "${BASH_SOURCE[0]}")"
BASE_NAME="update-package-list"

echo "Creating backup-packages.hook..."
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
Exec = /usr/local/bin/$BASE_NAME
EOF

echo "Installing hook..."
cp -v "$BASE_DIR/$BASE_NAME" "/usr/local/bin/$BASE_NAME"
chmod +x "/usr/local/bin/$BASE_NAME"

echo "✔ Hook and binary installed successfully."
