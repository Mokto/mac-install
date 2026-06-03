#!/bin/bash
set -euo pipefail

# Reinstall all casks to ~/Applications to avoid needing sudo for upgrades.
# System-level casks (drivers, CLI tools) are skipped.

APPDIR="$HOME/Applications"
mkdir -p "$APPDIR"

# Casks that install system drivers or CLI tools — skip appdir override
SKIP=(displaylink fastmail zed)

casks=$(brew list --cask)

for cask in $casks; do
    for skip in "${SKIP[@]}"; do
        if [[ "$cask" == "$skip" ]]; then
            echo "Skipping $cask (system-level)"
            continue 2
        fi
    done

    echo "==> Reinstalling $cask"
    if ! HOMEBREW_CASK_OPTS="--appdir=$APPDIR" brew reinstall --cask "$cask" 2>&1; then
        echo "  Failed, retrying with sudo..."
        sudo rm -rf "$APPDIR/${cask}.app" "/Applications/${cask}.app" 2>/dev/null || true
        HOMEBREW_CASK_OPTS="--appdir=$APPDIR" brew reinstall --cask "$cask"
    fi
done

echo ""
echo "Done. Add this to ~/.zshrc to make it permanent:"
echo '  export HOMEBREW_CASK_OPTS="--appdir=~/Applications"'
