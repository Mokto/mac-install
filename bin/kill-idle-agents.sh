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

  # Skip processes started less than 3 minutes ago — user may have just opened the chat
  proc_etime=$(ps -p "$pid" -o etime= 2>/dev/null | tr -d ' ')
  [[ -z "$proc_etime" ]] && continue
  # etime is [[DD-]HH:]MM:SS — if only MM:SS and minutes < 3, it's too fresh to kill
  if [[ "$proc_etime" =~ ^([0-9]+):([0-9]+)$ ]]; then
    [[ "${match[1]}" -lt 3 ]] && continue
  fi

  # Kill the process; only kill the parent wrapper if it has no other agent children
  kill "$pid" 2>/dev/null && ((killed++))
  other_children=$(ps -eo pid,ppid | awk -v ppid="$ppid" -v pid="$pid" '$2==ppid && $1!=pid' | wc -l | tr -d ' ')
  [[ "$other_children" -eq 0 ]] && kill "$ppid" 2>/dev/null
done

echo "$(date '+%Y-%m-%d %H:%M:%S') Killed $killed orphaned agent processes"
