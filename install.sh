#!/bin/zsh

# Install Homebrew if not present
if ! command -v brew >/dev/null; then
  echo "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Set up environment for current session
  if [[ -d /opt/homebrew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -d /usr/local/Homebrew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

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

git config --global user.name "Theo Mathieu"
git config --global user.email tmathieu.github@fastmail.com

./background/touchid.sh
./background/ssh-key.sh
./background/nodejs.sh
./background/zsh.sh

./dock.sh
