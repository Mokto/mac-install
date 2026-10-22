#!/bin/bash
# Deletes Cargo target/ dirs under ROOTS: every one idle for IDLE_DAYS, then the
# least recently built ones while free space is under MIN_FREE_GB. A dir built
# within the last hour is never touched.
set -euo pipefail

ROOTS=${ROOTS:-"$HOME/Projects $HOME/Ocean"}
IDLE_DAYS=${IDLE_DAYS:-3}
MIN_FREE_GB=${MIN_FREE_GB:-200}
DRY_RUN=${DRY_RUN:-0}

now=$(date +%s)

free_gb() { df -k "$HOME" | awk 'NR == 2 { print int($4 / 1048576) }'; }

# Every build that compiles something writes into target/[<triple>/]<profile>/deps,
# bumping that directory's mtime; files' own mtimes are copied from sources.
last_built() { find "$1" -maxdepth 3 -type d -exec stat -f %m {} + | sort -n | tail -1; }

targets=$(
  for root in $ROOTS; do
    find "$root" -maxdepth 4 -type d -name target -prune 2>/dev/null || true
  done | while IFS= read -r t; do
    if [[ -f "$(dirname "$t")/Cargo.toml" ]]; then echo "$(last_built "$t") $t"; fi
  done | sort -n
)

while read -r built t; do
  [[ -n ${t:-} ]] || continue
  age=$((now - built))
  ((age >= 3600)) || continue
  if ((age >= IDLE_DAYS * 86400)) || (($(free_gb) < MIN_FREE_GB)); then
    echo "$(date '+%F %T') removing $t ($(du -sh "$t" | cut -f1), last built $(date -r "$built" '+%F %T'), $(free_gb) GB free)"
    [[ $DRY_RUN == 1 ]] || rm -rf "$t"
  fi
done <<<"$targets"
