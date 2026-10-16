#!/bin/bash

if ! command -v rebase-editor >/dev/null; then
  echo "🔧 Installing rebase editor..."
  npm install -g rebase-editor
  git config --global sequence.editor rebase-editor
fi
