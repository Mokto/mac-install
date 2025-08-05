#!/bin/bash

# === CONFIG ===
KEY_TYPE="ed25519"
KEY_COMMENT="mac-setup-$(hostname)"
KEY_FILE="$HOME/.ssh/id_$KEY_TYPE"
LOG_FILE="$HOME/.ssh/generated_key_for_github.txt"

# === GENERATE KEY IF NOT EXISTS ===
if [ -f "$KEY_FILE" ]; then
  echo "SSH key already exists at $KEY_FILE. Skipping generation."
else
  echo "Generating new SSH key at $KEY_FILE..."
  ssh-keygen -t "$KEY_TYPE" -C "$KEY_COMMENT" -f "$KEY_FILE" -N ""
  echo "✅ SSH key generated."


    # === LOG PUBLIC KEY ===
    if [ -f "$KEY_FILE.pub" ]; then
      echo "✅ Public key saved. You can now add it to GitHub:"
      read -rsp "Enter your GitHub Personal Access Token: " GITHUB_TOKEN
      curl -H "Authorization: token $GITHUB_TOKEN" \
       -X POST https://api.github.com/user/keys \
       -d "{\"title\": \"Macbook\", \"key\": \"$(cat ~/.ssh/id_ed25519.pub)\"}"
    else
        echo "❌ Public key not found. Something went wrong."
        exit 1
    fi
fi
