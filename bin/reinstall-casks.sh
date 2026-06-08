#!/bin/bash
set -euo pipefail

# Detect and fix casks installed to /Applications that should live in ~/Applications.
# System-level casks (drivers, CLI tools) are intentionally kept in /Applications.

APPDIR="$HOME/Applications"
mkdir -p "$APPDIR"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

MARKER_DIR="$HOME/.cache/mac-install/casks"
mkdir -p "$MARKER_DIR"
target_casks=()
while IFS= read -r line; do
    target_casks+=("$line")
done < <(grep '^cask ' "$REPO_ROOT/Brewfile.apps" | sed 's/cask "\(.*\)"/\1/')

app_names() {
    brew info --json=v2 --cask "$1" 2>/dev/null \
        | jq -r '.casks[0].artifacts[] | select(has("app")) | .app[] | strings'
}

needs_reinstall() {
    local app
    while IFS= read -r app; do
        [[ -d "/Applications/$app" ]] && return 0
    done < <(app_names "$1")
    return 1
}

for cask in "${target_casks[@]}"; do
    [[ -f "$MARKER_DIR/$cask" ]] && continue

    brew list --cask "$cask" &>/dev/null || continue

    if ! needs_reinstall "$cask"; then
        echo "  $cask: ok"
        touch "$MARKER_DIR/$cask"
        continue
    fi

    echo "==> Fixing $cask (installed to /Applications, moving to ~/Applications)"
    if ! HOMEBREW_CASK_OPTS="--appdir=$APPDIR" brew reinstall --cask "$cask"; then
        echo "  Retrying with cleanup..."
        while IFS= read -r app; do
            sudo rm -rf "/Applications/$app" 2>/dev/null || true
        done < <(app_names "$cask")
        HOMEBREW_CASK_OPTS="--appdir=$APPDIR" brew reinstall --cask "$cask"
    fi
    touch "$MARKER_DIR/$cask"
done

