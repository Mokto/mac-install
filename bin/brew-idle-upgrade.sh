#!/bin/bash
set -euo pipefail

COOLDOWN=$((12 * 3600))     # 12 hours between runs
IDLE_THRESHOLD=$((15 * 60)) # require 15 minutes of idle
STATE_FILE="$HOME/.brew-idle-upgrade-last-run"

now=$(date +%s)

if [[ "${1:-}" != "--force" ]]; then
    idle_seconds=$(ioreg -c IOHIDSystem | awk '/HIDIdleTime/ {print int($NF/1000000000); exit}')
    if [[ "$idle_seconds" -lt "$IDLE_THRESHOLD" ]]; then
        exit 0
    fi

    last_run=$(cat "$STATE_FILE" 2>/dev/null || echo 0)
    if [[ $((now - last_run)) -lt "$COOLDOWN" ]]; then
        exit 0
    fi
fi

echo "$now" > "$STATE_FILE"

export PATH="/opt/homebrew/bin:$PATH"
brew update
brew upgrade --formula
brew upgrade --cask --greedy
brew cleanup
