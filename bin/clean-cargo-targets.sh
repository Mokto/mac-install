#!/bin/bash
# Deletes Cargo target/ dirs under ROOTS and built indexes (out-*/) in INDEX_ROOTS: every one
# idle for IDLE_DAYS, then the least recently built ones while free space is under MIN_FREE_GB.
# A dir built within the last hour, open in a process or named on a running command line is
# never touched, nor an index named `out` or holding a `.keep` file.
set -euo pipefail

ROOTS=${ROOTS:-"$HOME/Projects $HOME/Ocean"}
INDEX_ROOTS=${INDEX_ROOTS:-"$HOME/opengeocoding-index"}
IDLE_DAYS=${IDLE_DAYS:-3}
MIN_FREE_GB=${MIN_FREE_GB:-200}
DRY_RUN=${DRY_RUN:-0}

now=$(date +%s)

free_gb() { df -k "$HOME" | awk 'NR == 2 { print int($4 / 1048576) }'; }

# Every build that compiles something writes into target/[<triple>/]<profile>/deps,
# bumping that directory's mtime; files' own mtimes are copied from sources.
last_built() { find "$1" -maxdepth 3 -type d -exec stat -f %m {} + | sort -n | tail -1; }

# An index is written file by file, so its newest file is when it was last built.
last_written() { find "$1" -maxdepth 1 -exec stat -f %m {} + | sort -n | tail -1; }

# Open files (a service memory-maps its index) and command lines (INDEX_DIR=..., a build's
# output dir), so a dir in use is skipped even when nothing in it changed for hours.
in_use=$( (lsof -Fn 2>/dev/null | sed -n 's/^n//p') || true; ps -axww -o command= || true)
used() {
  local re
  re=$(printf '%s' "$1" | sed 's/[][\.*^$+?(){}|]/\\&/g')
  grep -qE "${re}(/|[[:space:]]|\$)" <<<"$in_use"
}

targets=$(
  {
    for root in $ROOTS; do
      find "$root" -maxdepth 4 -type d -name target -prune 2>/dev/null || true
    done | while IFS= read -r t; do
      if [[ -f "$(dirname "$t")/Cargo.toml" ]]; then echo "$(last_built "$t") $t"; fi
    done
    for root in $INDEX_ROOTS; do
      find "$root" -mindepth 1 -maxdepth 1 -type d -name 'out-*' 2>/dev/null || true
    done | while IFS= read -r t; do
      if [[ ! -e "$t/.keep" ]]; then echo "$(last_written "$t") $t"; fi
    done
  } | sort -n
)

while read -r built t; do
  [[ -n ${t:-} ]] || continue
  age=$((now - built))
  ((age >= 3600)) || continue
  used "$t" && continue
  if ((age >= IDLE_DAYS * 86400)) || (($(free_gb) < MIN_FREE_GB)); then
    echo "$(date '+%F %T') removing $t ($(du -sh "$t" | cut -f1), last built $(date -r "$built" '+%F %T'), $(free_gb) GB free)"
    # an index's builder.hash.txt sits beside it
    [[ $DRY_RUN == 1 ]] || rm -rf "$t" "$t.builder.hash.txt"
  fi
done <<<"$targets"
