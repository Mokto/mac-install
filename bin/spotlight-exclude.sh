#!/bin/bash
# Adds build and data dirs (or the paths given as arguments) to Spotlight's Privacy list, so
# mds stops reindexing target/, node_modules and multi-GB indexes after every build.
# Needs sudo, and Full Disk Access for the terminal: the list lives in an undocumented plist
# that System Settings writes, which a macOS update may move or stop honouring.
set -euo pipefail

PLIST=/System/Volumes/Data/.Spotlight-V100/VolumeConfiguration.plist
BUDDY=/usr/libexec/PlistBuddy

if [ $# -eq 0 ]; then
  set -- "$HOME/Projects" "$HOME/Ocean" "$HOME/geodata" "$HOME/opengeocoding-index" \
    "$HOME/Library/Caches/opengeocoding"
fi

if ! existing=$(sudo "$BUDDY" -c "Print :Exclusions" "$PLIST" 2>/dev/null | awk '{ sub(/^ +/, ""); print }'); then
  if ! sudo test -r "$PLIST"; then
    echo "Cannot read $PLIST: grant your terminal Full Disk Access" \
      "(System Settings > Privacy & Security) and rerun." >&2
    exit 1
  fi
  sudo "$BUDDY" -c "Add :Exclusions array" "$PLIST"
  existing=""
fi

added=0
for path in "$@"; do
  if grep -qxF "$path" <<<"$existing"; then
    echo "already excluded: $path"
  else
    sudo "$BUDDY" -c "Add :Exclusions: string $path" "$PLIST"
    echo "excluded: $path"
    added=1
  fi
done

if [ "$added" = 1 ]; then
  sudo launchctl kickstart -k system/com.apple.metadata.mds
fi
