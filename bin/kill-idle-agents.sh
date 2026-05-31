#!/bin/zsh
# Kill Zed agent processes (claude/gemini) whose session ID is no longer
# referenced in Zed's sidebar_threads database.

ZED_DB="/Users/theo/Library/Application Support/Zed/db/0-stable/db.sqlite"

archived_sessions=$(sqlite3 "$ZED_DB" \
  "SELECT session_id FROM sidebar_threads WHERE archived=1 AND session_id != '';")

killed=0

ps -eo pid,ppid,args | grep -E "claude-agent-sdk|claude --output|gemini-cli.*--acp|claude-agent-acp" | grep -v grep | while read pid ppid args; do
  session_id=$(echo "$args" | grep -oE '(--session-id|--resume) [a-f0-9-]+' | awk '{print $2}')

  # Skip processes without a session ID (npm wrappers — their child will match)
  [[ -z "$session_id" ]] && continue

  # Only kill if session is explicitly archived in Zed
  echo "$archived_sessions" | grep -qF "$session_id" || continue

  # Kill the process and its parent npm wrapper
  kill "$pid" "$ppid" 2>/dev/null && ((killed++))
done

echo "Killed $killed orphaned agent processes"
