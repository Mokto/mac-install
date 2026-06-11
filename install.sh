#!/bin/zsh

# Install Homebrew if not present
if ! command -v brew >/dev/null; then
  echo "Setting up Homebrew..."
  eval "$(/opt/homebrew/bin/brew shellenv)"
  echo "Homebrew installed and environment updated for current session."
fi


mkdir -p "$HOME/Applications"

# Formulae + system casks that require /Applications
brew bundle --file Brewfile || { echo "Error: Brewfile installation failed."; exit 1; }

# Regular casks go to ~/Applications (no sudo needed for upgrades)
HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications" brew bundle --file Brewfile.apps || { echo "Error: Brewfile.apps installation failed."; exit 1; }

# Fix any casks that landed in /Applications instead of ~/Applications
./bin/reinstall-casks.sh

ln -sf "$(pwd)/dotfiles/.zshrc" "$HOME/.zshrc"
ln -sf "$(pwd)/dotfiles/.zimrc" "$HOME/.zimrc"
ln -sf "$(pwd)/dotfiles/.p10k.zsh" "$HOME/.p10k.zsh"
ln -sf "$(pwd)/dotfiles/zed.json" "$HOME/.config/zed/settings.json"
ln -sf "$(pwd)/dotfiles/zed-keymap.json" "$HOME/.config/zed/keymap.json"
ln -sf "$(pwd)/dotfiles/.gitconfig" "$HOME/.gitconfig"
ln -sf "$(pwd)/dotfiles/.gitconfig-github" "$HOME/.gitconfig-github"
ln -sf "$(pwd)/dotfiles/.gitconfig-ocean" "$HOME/.gitconfig-ocean"
ln -sf "$(pwd)/dotfiles/allowed_signers" "$HOME/.ssh/allowed_signers"
mkdir -p "$HOME/.claude"
ln -sf "$(pwd)/dotfiles/claude-settings.json" "$HOME/.claude/settings.json"
ln -sf "$(pwd)/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

echo "export MAC_INSTALL_DIR=\"$(pwd)\"" > "$HOME/.mac-install.env"

./background/touchid.sh
./background/nodejs.sh
./background/zsh.sh

./dock.sh

# Idle-aware brew upgrade: runs when idle 15min+, at most every 12 hours
chmod +x "$(pwd)/bin/brew-idle-upgrade.sh"
IDLE_PLIST_DST="$HOME/Library/LaunchAgents/com.theo.brew-idle-upgrade.plist"
sed "s|INSTALL_DIR|$(pwd)|g; s|HOME_DIR|$HOME|g" \
  "$(pwd)/launchagents/com.theo.brew-idle-upgrade.plist" > "$IDLE_PLIST_DST"
launchctl unload "$IDLE_PLIST_DST" 2>/dev/null || true
launchctl load "$IDLE_PLIST_DST"
