#!/bin/zsh

# Install Homebrew if not present
which brew >/dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew bundle --file=./Brewfile

ln -sf ./dotfiles/.zshrc ~/.zshrc
ln -sf ./dotfiles/.gitconfig ~/.gitconfig