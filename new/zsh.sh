#!/bin/zsh
set -euo pipefail

# === CONFIG ===
ZIM_PATH="/opt/homebrew/opt/zimfw/share/zimfw.zsh"
ZSHRC="$HOME/.zshrc"
ZIMRC="$HOME/.zimrc"
ZIM_HOME="$HOME/.zim"

# === 1. Install zimfw via Homebrew if missing ===
if ! brew list --formula | grep -q "^zimfw$"; then
  echo "🔧 Installing zimfw with Homebrew..."
  brew install zimfw
fi


# === 4. Run zimfw install if init.zsh is missing ===
if [ ! -f "$ZIM_HOME/init.zsh" ]; then
  echo "🚀 Running zimfw install..."
  ZDOTDIR="$HOME"  ZIM_HOME="$ZIM_HOME" zsh -c "source $ZIM_PATH init && zimfw install"
  echo "🎉 Zimfw setup complete. Restart your terminal or run: source ~/.zshrc"
fi

source $ZIM_PATH init && zimfw build
