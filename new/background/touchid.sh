#!/bin/bash

SUDO_PAM="/etc/pam.d/sudo"
TOUCHID_LINE="auth       sufficient     pam_tid.so"

# Check if pam_tid.so is already enabled
if ! grep -Fxq "$TOUCHID_LINE" "$SUDO_PAM"; then
  echo "Enabling Touch ID for sudo..."
  sudo cp "$SUDO_PAM" "$SUDO_PAM.backup.$(date +%s)" # backup original
  echo -e "$TOUCHID_LINE\n$(cat "$SUDO_PAM")" | sudo tee "$SUDO_PAM" > /dev/null
  echo "✅ Touch ID enabled for sudo"
else
  echo "Touch ID for sudo is already enabled"
fi