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

ln -sf ./dotfiles/.zshrc ~/.zshrc
# ln -sf ./dotfiles/.gitconfig ~/.gitconfig


./dock.sh
./touchid.sh
./ssh-key.sh
