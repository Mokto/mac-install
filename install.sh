#!/bin/zsh

# Install Homebrew if not present
if ! command -v brew >/dev/null; then
  echo "Setting up Homebrew..."
  eval "$(/opt/homebrew/bin/brew shellenv)"
  echo "Homebrew installed and environment updated for current session."
fi


brew bundle

# if fails, stop the script
if [[ $? -ne 0 ]]; then
  echo "Error: Homebrew bundle installation failed."
  exit 1
fi

ln -sf "$(pwd)/dotfiles/.zshrc" "$HOME/.zshrc"
ln -sf "$(pwd)/dotfiles/.zimrc" "$HOME/.zimrc"
ln -sf "$(pwd)/dotfiles/zed.json" "$HOME/.config/zed/settings.json"
ln -sf "$(pwd)/dotfiles/zed-keymap.json" "$HOME/.config/zed/keymap.json"
ln -sf "$(pwd)/dotfiles/.gitconfig" "$HOME/.gitconfig"
ln -sf "$(pwd)/dotfiles/.gitconfig-github" "$HOME/.gitconfig-github"
ln -sf "$(pwd)/dotfiles/.gitconfig-ocean" "$HOME/.gitconfig-ocean"
ln -sf "$(pwd)/dotfiles/allowed_signers" "$HOME/.ssh/allowed_signers"
mkdir -p "$HOME/.claude"
ln -sf "$(pwd)/dotfiles/claude-settings.json" "$HOME/.claude/settings.json"

./background/touchid.sh
./background/nodejs.sh
./background/zsh.sh

./dock.sh

brew tap domt4/autoupdate
brew autoupdate start 43200 --upgrade --cleanup

# Install kill-idle-agents launchd service
PLIST_DST="$HOME/Library/LaunchAgents/com.theo.kill-idle-agents.plist"
mkdir -p "$HOME/Library/LaunchAgents"
sed "s|/Users/theo/Projects/mac-install|$(pwd)|g" \
  "$(pwd)/launchagents/com.theo.kill-idle-agents.plist" > "$PLIST_DST"
launchctl unload "$PLIST_DST" 2>/dev/null
launchctl load "$PLIST_DST"
