#!/bin/bash

sudo spctl --master-disable

# brew install \
#     zsh-completions

brew tap homebrew/cask-fonts
brew cask install font-hack-nerd-font iterm2 visual-studio-code 1password google-chrome gpg-suite

code --install-extension dbaeumer.vscode-eslint
code --install-extension jpoissonnier.vscode-styled-components
code --install-extension vscode-icons-team.vscode-icons
code --install-extension whizkydee.material-palenight-theme
code --install-extension EditorConfig.EditorConfig
code --install-extension eamodio.gitlens
code --install-extension zxh404.vscode-proto3
code --install-extension silvenon.mdx
code --install-extension stylelint.vscode-stylelint
code --install-extension usernamehw.errorlens
code --install-extension golang.go

cp confs/vscode.json ~/Library/Application\ Support/Code/User/settings.json