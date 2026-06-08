#!/bin/bash
set -euo pipefail

COOLDOWN=$((12 * 3600))     # 12 hours between runs
IDLE_THRESHOLD=$((4 * 60)) # require 4 minutes of idle
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
mapfile -t user_casks < <(
    brew info --json=v2 --installed 2>/dev/null | python3 -c "
import json, sys, os
seen = set()
for cask in json.load(sys.stdin).get('casks', []):
    token = cask['token']
    if token in seen: continue
    for artifact in cask.get('artifacts', []):
        if isinstance(artifact, dict) and 'app' in artifact:
            for app in artifact['app']:
                if os.path.isdir(os.path.expanduser('~/Applications/' + app)):
                    print(token); seen.add(token); break
"
)
[[ ${#user_casks[@]} -gt 0 ]] && brew upgrade --cask --greedy "${user_casks[@]}"
brew cleanup
